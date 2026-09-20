import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_providers.dart';
import 'player_store.dart';
import 'settings_providers.dart';

/// Latéralité à appliquer AU SIÈGE COURANT : celle du joueur dont c'est le
/// tour, quand il est rattaché à une fiche.
///
/// Repli sur le réglage d'appareil dans tous les autres cas — un bot, qui n'a
/// pas de latéralité ; une partie enregistrée avant la base de joueurs, qui ne
/// porte aucun lien ; un état chargé en test. La disposition des commandes
/// peut donc basculer d'un côté à l'autre en cours de partie, ce qui est le
/// comportement voulu : elle suit la main de qui joue.
final currentSeatRightHandedProvider = Provider<bool>((ref) {
  final deviceDefault = ref.watch(settingsProvider).rightHanded;
  final engine = ref.watch(gameProvider);
  if (engine == null) return deviceDefault;

  // `GameNotifier` expose la config RÉORDONNÉE : c'est bien elle qu'indexe
  // `currentPlayerIndex`.
  final id = ref.watch(gameProvider.notifier).rotatedSetup?.playerIdAt(engine.currentPlayerIndex);
  if (id == null) return deviceDefault;

  final players = ref.watch(playersProvider).value;
  if (players == null) return deviceDefault;
  for (final player in players) {
    if (player.id == id) return player.rightHanded;
  }
  return deviceDefault;
});
