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

/// Nom sous lequel afficher chaque joueur de la partie en cours : son surnom
/// quand son siège est rattaché à une fiche qui en porte un.
///
/// Table indexée par le nom EN JEU (`Player.name`) — c'est ce que tous les
/// rendus ont sous la main, `Player` ignorant tout des fiches. Un siège non
/// rattaché n'y figure pas du tout : un bot, une partie antérieure à la base,
/// une fiche supprimée. L'appelant retombe alors sur le nom, c'est-à-dire sur
/// ce que la partie a réellement enregistré.
///
/// Le blason, lui, continue de se dessiner à partir du NOM : c'est un repère
/// d'identité stable, qui ne doit pas changer le jour où le joueur se choisit
/// un surnom.
final displayNamesProvider = Provider<Map<String, String>>((ref) {
  final engine = ref.watch(gameProvider);
  final setup = ref.watch(gameProvider.notifier).rotatedSetup;
  final profiles = ref.watch(playersProvider).value;
  if (engine == null || setup == null || profiles == null) return const {};

  final byId = {for (final profile in profiles) profile.id: profile};
  final names = <String, String>{};
  for (var seat = 0; seat < engine.players.length; seat++) {
    final profile = byId[setup.playerIdAt(seat)];
    if (profile == null) continue;
    final inGame = engine.players[seat].name;
    // Rien à substituer quand le surnom est absent : la table reste vide et
    // l'appelant garde le nom, sans détour.
    if (profile.displayName != inGame) names[inGame] = profile.displayName;
  }
  return names;
});

/// Nom à afficher pour [name], ou [name] lui-même faute de mieux.
String displayNameOf(Map<String, String> displayNames, String name) =>
    displayNames[name] ?? name;
