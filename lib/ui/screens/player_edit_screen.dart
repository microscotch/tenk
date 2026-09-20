import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_store.dart';
import '../widgets/player_avatar.dart';

/// Création ou édition d'une fiche joueur.
///
/// [existing] nul crée une fiche neuve ; sinon la fiche est modifiée en place,
/// ses statistiques intactes — elles ne sont jamais touchées ici.
class PlayerEditScreen extends ConsumerStatefulWidget {
  final PlayerProfile? existing;

  const PlayerEditScreen({super.key, this.existing});

  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _nickname;
  late bool _rightHanded;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _nickname = TextEditingController(text: widget.existing?.nickname ?? '');
    _rightHanded = widget.existing?.rightHanded ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  /// Enregistre et rend la fiche à l'appelant (voir [PlayerPickerScreen], qui
  /// s'en sert pour sélectionner d'office le joueur qu'on vient de créer).
  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.playerNameRequiredError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final store = ref.read(playerStoreProvider);
    if (await store.nameTaken(name, exceptId: widget.existing?.id)) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = l10n.playerNameTakenError;
      });
      return;
    }

    final nickname = _nickname.text.trim();
    final existing = widget.existing;
    // Un renommage passe par `renamedTo`, qui conserve l'ancien nom : les
    // parties archivées ne contiennent que des noms, et c'est par eux qu'elles
    // se rattachent à une fiche.
    final saved = existing == null
        ? PlayerProfile.create(name: name, nickname: nickname, rightHanded: _rightHanded)
        : existing.renamedTo(name).copyWith(
              nickname: nickname.isEmpty ? null : nickname,
              clearNickname: nickname.isEmpty,
              rightHanded: _rightHanded,
            );

    await store.write(saved);
    ref.invalidate(playersProvider);
    if (!mounted) return;
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? l10n.newPlayerTitle : l10n.editPlayerTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                // Le blason se dessine à partir du nom : il se met à jour en
                // direct pendant la frappe, ce qui montre à quoi le joueur
                // ressemblera à table.
                child: PlayerAvatarWidget(name: name.isEmpty ? '?' : name, size: 72),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _name,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.playerNameLabel,
                  errorText: _error,
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nickname,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l10n.playerNicknameLabel),
              ),
              const SizedBox(height: 24),
              Text(l10n.settingsHandednessLabel, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: true, label: Text(l10n.settingsHandednessRight)),
                  ButtonSegment(value: false, label: Text(l10n.settingsHandednessLeft)),
                ],
                selected: {_rightHanded},
                onSelectionChanged: (s) => setState(() => _rightHanded = s.first),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(l10n.validateButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
