import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/avatar_catalog.dart';
import '../../game/online/protocol.dart' show isValidOnlineName;
import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/player_avatar.dart';

/// Création ou édition d'une fiche joueur.
///
/// [existing] nul crée une fiche neuve ; sinon la fiche est modifiée en place,
/// ses statistiques intactes — elles ne sont jamais touchées ici.
///
/// [isMyProfile] : la fiche est (ou sera) le profil de l'utilisateur. Son nom
/// affiché devient alors son pseudo en ligne, et doit en passer les règles
/// ([isValidOnlineName]) : c'est ici qu'on le corrige, pas au moment de
/// rejoindre un salon. [initialName] et [initialRightHanded] préremplissent une
/// fiche neuve (l'ancien nom et la latéralité des réglages).
class PlayerEditScreen extends ConsumerStatefulWidget {
  final PlayerProfile? existing;
  final bool isMyProfile;
  final String? initialName;
  final bool? initialRightHanded;

  const PlayerEditScreen({
    super.key,
    this.existing,
    this.isMyProfile = false,
    this.initialName,
    this.initialRightHanded,
  });

  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _nickname;
  late bool _rightHanded;
  String? _avatarColor;
  String? _avatarAnimal;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? widget.initialName ?? '');
    _nickname = TextEditingController(text: widget.existing?.nickname ?? '');
    _rightHanded = widget.existing?.rightHanded ?? widget.initialRightHanded ?? true;
    _avatarColor = widget.existing?.avatarColor;
    _avatarAnimal = widget.existing?.avatarAnimal;
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
    final nickname = _nickname.text.trim();
    if (widget.isMyProfile && !isValidOnlineName(nickname.isEmpty ? name : nickname)) {
      setState(() => _error = l10n.onlineNameInvalidError);
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

    final existing = widget.existing;
    // Un renommage passe par `renamedTo`, qui conserve l'ancien nom : les
    // parties archivées ne contiennent que des noms, et c'est par eux qu'elles
    // se rattachent à une fiche.
    final saved = existing == null
        ? PlayerProfile.create(
            name: name,
            nickname: nickname,
            rightHanded: _rightHanded,
            avatarColor: _avatarColor,
            avatarAnimal: _avatarAnimal,
          )
        : existing
              .renamedTo(name)
              .copyWith(
                nickname: nickname.isEmpty ? null : nickname,
                clearNickname: nickname.isEmpty,
                rightHanded: _rightHanded,
                avatarColor: _avatarColor,
                clearAvatarColor: _avatarColor == null,
                avatarAnimal: _avatarAnimal,
                clearAvatarAnimal: _avatarAnimal == null,
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
    // La pastille montre la lettre du nom affiché, le surnom d'abord.
    final nickname = _nickname.text.trim();
    final shownName = nickname.isNotEmpty ? nickname : name;
    return Scaffold(
      appBar: AppTopBar(
        title: Text(
          widget.isMyProfile
              ? l10n.myProfileTitle
              : (widget.existing == null ? l10n.newPlayerTitle : l10n.editPlayerTitle),
        ),
      ),
      // « Valider » reste en bas de l'écran, hors de ce qui défile : avec le choix de
      // la pastille la fiche est plus haute qu'un petit téléphone, et le bouton ne
      // doit pas se trouver au bout d'un défilement.
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      // La pastille se met à jour en direct pendant la frappe et les
                      // choix ci-dessous : elle montre à quoi le joueur ressemblera à table.
                      child: PlayerAvatarWidget(
                        name: shownName.isEmpty ? '?' : shownName,
                        size: 72,
                        color: avatarColorById(_avatarColor) == null
                            ? null
                            : Color(avatarColorById(_avatarColor)!.argb),
                        animal: _avatarAnimal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _name,
                      autofocus: widget.existing == null,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l10n.playerNameLabel, errorText: _error),
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nickname,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: l10n.playerNicknameLabel),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.avatarSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    AvatarPicker(
                      name: shownName.isEmpty ? '?' : shownName,
                      color: _avatarColor,
                      animal: _avatarAnimal,
                      onColor: (id) => setState(() => _avatarColor = id),
                      onAnimal: (id) => setState(() => _avatarAnimal = id),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _saving ? null : _save, child: Text(l10n.validateButton)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
