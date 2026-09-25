import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_store.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';
import 'player_edit_screen.dart';

/// Sélection multiple dans la base de joueurs, pour composer une partie.
///
/// Rend la liste des fiches choisies, ou `null` si l'écran est quitté sans
/// valider. [alreadySeated] grise les joueurs déjà assis : on ne peut pas
/// jouer deux fois dans la même partie.
class PlayerPickerScreen extends ConsumerStatefulWidget {
  final Set<String> alreadySeated;

  const PlayerPickerScreen({super.key, this.alreadySeated = const {}});

  @override
  ConsumerState<PlayerPickerScreen> createState() => _PlayerPickerScreenState();
}

class _PlayerPickerScreenState extends ConsumerState<PlayerPickerScreen> {
  final Set<String> _selected = {};

  Future<void> _createPlayer() async {
    final created = await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute(builder: (_) => const PlayerEditScreen()),
    );
    if (!mounted || created == null) return;
    // Un joueur qu'on vient de créer est évidemment celui qu'on voulait :
    // il est sélectionné d'office, sans avoir à le rechercher dans la liste.
    setState(() => _selected.add(created.id));
    ref.invalidate(playersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final players = ref.watch(playersProvider).value ?? const <PlayerProfile>[];

    return Scaffold(
      appBar: AppTopBar(
        title: Text(l10n.pickPlayersTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: l10n.createPlayerButton,
            onPressed: _createPlayer,
          ),
        ],
      ),
      body: SafeArea(
        child: players.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.noPlayersToPickMessage, textAlign: TextAlign.center),
                ),
              )
            : ListView(
                children: [
                  for (final player in players)
                    CheckboxListTile(
                      value: _selected.contains(player.id),
                      onChanged: widget.alreadySeated.contains(player.id)
                          ? null
                          : (checked) => setState(() {
                                if (checked ?? false) {
                                  _selected.add(player.id);
                                } else {
                                  _selected.remove(player.id);
                                }
                              }),
                      secondary: PlayerAvatarWidget(name: player.name, size: 40),
                      title: Text(player.displayName),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _selected.isEmpty
                ? null
                : () => Navigator.of(context)
                    .pop(players.where((p) => _selected.contains(p.id)).toList()),
            child: Text(l10n.validateButton),
          ),
        ),
      ),
    );
  }
}
