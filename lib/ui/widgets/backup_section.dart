import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/backup_archive.dart';
import '../../state/backup_service.dart';
import '../../state/game_providers.dart';
import '../../state/game_save_store.dart';
import '../../state/online_providers.dart';
import '../../state/player_statistics.dart';
import '../../state/player_store.dart';
import '../../state/settings_providers.dart';
import '../backup_files.dart';
import '../theme.dart';

/// La section « Sauvegarde des données » des paramètres : exporter les parties,
/// les fiches joueurs et les réglages dans un fichier protégé par un mot de
/// passe, et restaurer un tel fichier (voir [BackupService]).
///
/// [onRestored] est appelé après une restauration réussie : l'écran qui porte la
/// section affiche des valeurs lues avant, et doit se refermer ou se relire.
class BackupSection extends ConsumerWidget {
  final VoidCallback onRestored;

  const BackupSection({super.key, required this.onRestored});

  /// Le nom de compte donné au gestionnaire de mots de passe : il range le mot de
  /// passe sous ce nom, qui ne dépend pas de la langue.
  static const accountName = 'TenK';

  static String _fileName() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'tenk-${now.year}-${two(now.month)}-${two(now.day)}.tenkbak';
  }

  static String failureMessage(AppLocalizations l10n, BackupFailure failure) => switch (failure) {
        BackupFailure.notABackup => l10n.backupNotABackup,
        BackupFailure.unsupportedVersion => l10n.backupTooNew,
        BackupFailure.wrongPassword => l10n.backupWrongPassword,
        BackupFailure.corrupted => l10n.backupCorrupted,
      };

  /// Une partie en cours (locale ou en ligne) tient des fichiers que la
  /// restauration écraserait : on la refuse tant qu'elle dure.
  bool _blocked(WidgetRef ref) =>
      ref.read(gameProvider.notifier).hasLiveLocalGame ||
      ref.read(gameProvider.notifier).isOnline ||
      ref.read(onlineSessionProvider).inRoom;

  void _refresh(WidgetRef ref) {
    ref.invalidate(settingsProvider);
    ref.invalidate(playersProvider);
    ref.invalidate(pausedGamesProvider);
    ref.invalidate(finishedGamesProvider);
    ref.invalidate(playerStatisticsSyncProvider);
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;

    final password = await showDialog<String>(context: context, builder: (_) => const _ExportDialog());
    if (password == null || !context.mounted) return;

    final busy = _showBusy(context, l10n);
    try {
      final bytes = await ref.read(backupServiceProvider).export(password);
      busy.close();
      await ref.read(shareBackupFileProvider)(bytes, _fileName(), origin: origin);
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupExported)));
    } catch (_) {
      busy.close();
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(backupServiceProvider);

    if (_blocked(ref)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupBlockedByGame)));
      return;
    }
    final bytes = await ref.read(pickBackupFileProvider)();
    if (bytes == null) return;
    try {
      service.check(bytes);
    } on BackupException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(failureMessage(l10n, e.failure))));
      return;
    }
    if (!context.mounted) return;

    final opened = await showDialog<_Opened>(context: context, builder: (_) => _ImportDialog(service: service, bytes: bytes));
    if (opened == null || !context.mounted) return;

    try {
      final result = await service.restore(opened.archive, opened.mode);
      _refresh(ref);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          content: Text(l10n.backupRestored(result.games, result.profiles)),
          actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.backupOk))],
        ),
      );
      onRestored();
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.backupSectionTitle, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.backupSectionHint, style: TextStyle(color: TableColors.of(context).muted, fontSize: 12)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.backupExportButton),
              onPressed: () => _export(context, ref),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(l10n.backupImportButton),
              onPressed: () => _import(context, ref),
            ),
          ],
        ),
      ],
    );
  }
}

/// Un dialogue d'attente, pour les quelques secondes de la dérivation de la clef.
class _Busy {
  final NavigatorState _navigator;
  bool _open = true;

  _Busy(this._navigator);

  void close() {
    if (!_open) return;
    _open = false;
    _navigator.pop();
  }
}

_Busy _showBusy(BuildContext context, AppLocalizations l10n) {
  final navigator = Navigator.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            const SizedBox(width: 20),
            Expanded(child: Text(l10n.backupWorking)),
          ],
        ),
      ),
    ),
  );
  return _Busy(navigator);
}

/// Le champ « identifiant » que les gestionnaires de mots de passe exigent pour
/// ranger un mot de passe : le même nom pour toutes les sauvegardes, non modifiable.
Widget _accountField(AppLocalizations l10n) => TextFormField(
      initialValue: BackupSection.accountName,
      readOnly: true,
      autofillHints: const [AutofillHints.username],
      decoration: InputDecoration(labelText: l10n.backupAccountLabel, border: const OutlineInputBorder()),
    );

/// Choisit le mot de passe d'un export : deux saisies, d'au moins
/// [BackupEnvelope.minPasswordLength] caractères. Le système propose d'enregistrer
/// le mot de passe dans son gestionnaire dès qu'il est validé.
class _ExportDialog extends StatefulWidget {
  const _ExportDialog();

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    // Valide le formulaire auprès du système : il propose d'enregistrer le mot de
    // passe dans son gestionnaire.
    TextInput.finishAutofillContext();
    Navigator.of(context).pop(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupExportTitle),
      content: SingleChildScrollView(
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.backupExportExplain),
                const SizedBox(height: 16),
                _accountField(l10n),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: l10n.backupPasswordLabel, border: const OutlineInputBorder()),
                  validator: (v) => (v ?? '').length < BackupEnvelope.minPasswordLength
                      ? l10n.backupPasswordTooShort(BackupEnvelope.minPasswordLength)
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(labelText: l10n.backupPasswordConfirmLabel, border: const OutlineInputBorder()),
                  validator: (v) => v != _password.text ? l10n.backupPasswordMismatch : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _submit, child: Text(l10n.backupExportConfirm)),
      ],
    );
  }
}

/// Ce que le dialogue d'import rend : l'archive déchiffrée et le mode choisi.
class _Opened {
  final BackupArchive archive;
  final BackupImportMode mode;
  const _Opened(this.archive, this.mode);
}

/// Demande le mot de passe et le mode de restauration, et déchiffre le fichier
/// dans le dialogue même : un mot de passe faux se corrige sur place, sans
/// repasser par le choix du fichier.
class _ImportDialog extends StatefulWidget {
  final BackupService service;
  final Uint8List bytes;

  const _ImportDialog({required this.service, required this.bytes});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  final _password = TextEditingController();
  BackupImportMode _mode = BackupImportMode.merge;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final archive = await widget.service.open(widget.bytes, _password.text);
      TextInput.finishAutofillContext(shouldSave: false);
      navigator.pop(_Opened(archive, _mode));
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = BackupSection.failureMessage(l10n, e.failure));
    } catch (_) {
      if (mounted) setState(() => _error = l10n.backupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.backupImportTitle),
      content: SingleChildScrollView(
        child: AutofillGroup(
          onDisposeAction: AutofillContextAction.cancel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _accountField(l10n),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                obscureText: true,
                autofocus: true,
                enabled: !_busy,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: l10n.backupPasswordLabel,
                  errorText: _error,
                  errorMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              RadioGroup<BackupImportMode>(
                groupValue: _mode,
                onChanged: (mode) => setState(() => _mode = mode ?? _mode),
                child: Column(
                  children: [
                    RadioListTile<BackupImportMode>(
                      contentPadding: EdgeInsets.zero,
                      value: BackupImportMode.merge,
                      title: Text(l10n.backupImportModeMerge),
                      subtitle: Text(l10n.backupImportModeMergeHint),
                    ),
                    RadioListTile<BackupImportMode>(
                      contentPadding: EdgeInsets.zero,
                      value: BackupImportMode.replace,
                      title: Text(l10n.backupImportModeReplace),
                      subtitle: Text(l10n.backupImportModeReplaceHint),
                    ),
                  ],
                ),
              ),
              if (_busy) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.of(context).pop(), child: Text(l10n.cancelButton)),
        FilledButton(onPressed: _busy ? null : _submit, child: Text(l10n.backupImportConfirm)),
      ],
    );
  }
}
