import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';
import '../../state/settings_providers.dart';
import '../online_messages.dart';
import '../widgets/app_top_bar.dart';
import 'online_dice_off_screen.dart';
import 'online_room_screen.dart';

/// L'entrée des parties en ligne : créer un salon, ou rejoindre celui dont on a
/// le code. Quand une partie en ligne est déjà en cours, on la retrouve (ou on
/// la quitte) ici plutôt que d'en ouvrir une seconde.
class OnlineEntryScreen extends ConsumerStatefulWidget {
  const OnlineEntryScreen({super.key});

  @override
  ConsumerState<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends ConsumerState<OnlineEntryScreen> {
  late final TextEditingController _name;
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(settingsProvider).playerName);
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  bool get _nameOk => _name.text.trim().isNotEmpty;

  /// Ouvre l'écran qui correspond à l'état de la session : le salon, ou la
  /// partie déjà commencée. Si le [GameNotifier] a servi à autre chose depuis
  /// (une partie locale, un rejeu), la partie en ligne y est d'abord remise en
  /// place à partir du journal du serveur.
  Future<void> _openCurrent() async {
    final session = ref.read(onlineSessionProvider.notifier);
    final started = ref.read(onlineSessionProvider).gameStarted;
    if (started && !await session.reopenGame()) return;
    if (!mounted) return;
    final Widget screen = started ? const OnlineDiceOffScreen() : const OnlineRoomScreen();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onlineLeaveConfirmTitle),
        content: Text(l10n.onlineLeaveConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.onlineLeaveButton)),
        ],
      ),
    );
    if (leave != true) return;
    final online = ref.read(onlineSessionProvider);
    final session = ref.read(onlineSessionProvider.notifier);
    // Une partie commencée garde la place du joueur (elle l'attend, comme le dit
    // la fenêtre) ; un salon qui n'a pas commencé, ou une partie finie, se quitte.
    if (online.gameStarted && online.phase != RoomPhase.over) {
      await session.disconnect();
    } else {
      await session.leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(onlineSessionProvider);
    ref.listen<OnlineState>(onlineSessionProvider, (previous, next) {
      if (next.errorSerial != (previous?.errorSerial ?? 0) && next.error != null) {
        final message = onlineErrorMessage(l10n, next.error!, unreachable: next.unreachable);
        if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      // Le serveur vient de décrire le salon pour la première fois : on y va.
      if (previous?.phase == null && next.phase != null && next.roomCode != null) _openCurrent();
    });

    final connecting = online.status == OnlineStatus.connecting;
    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.onlineTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: online.inRoom ? _inRoom(l10n, online) : _entry(l10n, connecting),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inRoom(AppLocalizations l10n, OnlineState online) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(online.roomCode!, style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _openCurrent,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.onlineResumeButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmLeave,
          icon: const Icon(Icons.logout),
          label: Text(l10n.onlineLeaveButton),
        ),
      ],
    );
  }

  Widget _entry(AppLocalizations l10n, bool connecting) {
    final session = ref.read(onlineSessionProvider.notifier);
    final saved = ref.watch(onlineSavedGameProvider).value;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Une place gardée dans une partie en ligne (déconnexion volontaire,
        // app fermée) : la retrouver passe avant d'en ouvrir une autre.
        if (saved != null) ...[
          FilledButton.icon(
            onPressed: connecting ? null : session.tryResume,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.onlineResumeButton),
          ),
          const SizedBox(height: 24),
        ],
        TextField(
          controller: _name,
          maxLength: 20,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.onlineNameLabel, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: connecting || !_nameOk ? null : () => session.create(_name.text.trim()),
          icon: const Icon(Icons.add),
          label: Text(l10n.onlineCreateButton),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l10n.onlineOrDivider)),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l10n.onlineCodeLabel, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: connecting || !_nameOk || _code.text.trim().length != 5
              ? null
              : () => session.join(_code.text, _name.text.trim()),
          icon: const Icon(Icons.login),
          label: Text(l10n.onlineJoinButton),
        ),
        if (connecting) ...[
          const SizedBox(height: 24),
          Center(child: Text(l10n.onlineConnecting)),
        ],
      ],
    );
  }
}
