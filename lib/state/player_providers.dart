import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/player_profile.dart';
import 'game_providers.dart';
import 'game_save_store.dart';
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

/// Nom sous lequel afficher chaque joueur d'UNE partie, décrite par sa config
/// [setup] : son surnom quand son siège est rattaché à une fiche qui en porte
/// un.
///
/// Table indexée par le nom EN JEU (`Player.name`) — c'est ce que tous les
/// rendus ont sous la main, `Player` ignorant tout des fiches. Un siège non
/// rattaché n'y figure pas du tout : un bot, une partie antérieure à la base,
/// une fiche supprimée. L'appelant retombe alors sur le nom, c'est-à-dire sur
/// ce que la partie a réellement enregistré.
///
/// Le lien est l'identifiant de la fiche, jamais le nom : une fiche renommée
/// depuis la partie garde son surnom, et deux parties qui ont un joueur du même
/// nom en jeu ne se prêtent pas leurs surnoms. C'est pourquoi la table se
/// calcule depuis la config de la partie AFFICHÉE — celle du journal d'un run
/// archivé, par exemple — et non depuis la partie en cours, qui peut n'exister
/// pas, ou être une autre.
///
/// Le blason, lui, continue de se dessiner à partir du NOM : c'est un repère
/// d'identité stable, qui ne doit pas changer le jour où le joueur se choisit
/// un surnom.
Map<String, String> displayNamesFor(GameSetup setup, Iterable<PlayerProfile>? profiles) {
  if (profiles == null) return const {};
  final byId = {for (final profile in profiles) profile.id: profile};
  final names = <String, String>{};
  for (var seat = 0; seat < setup.playerNames.length; seat++) {
    final profile = byId[setup.playerIdAt(seat)];
    if (profile == null) continue;
    final inGame = setup.playerNames[seat];
    // Rien à substituer quand le surnom est absent : la table reste vide et
    // l'appelant garde le nom, sans détour.
    if (profile.displayName != inGame) names[inGame] = profile.displayName;
  }
  return names;
}

/// Les noms à afficher pour la partie EN COURS (ou en rejeu) : voir
/// [displayNamesFor], appliqué à sa config réordonnée — celle que porte le
/// moteur exposé par [gameProvider].
final displayNamesProvider = Provider<Map<String, String>>((ref) {
  final engine = ref.watch(gameProvider);
  final setup = ref.watch(gameProvider.notifier).rotatedSetup;
  if (engine == null || setup == null) return const {};
  return displayNamesFor(setup, ref.watch(playersProvider).value);
});

/// Les noms à afficher pour la partie que montre un écran : celle de son
/// journal [record] quand il en a un — une partie terminée, archivée ou non —
/// et sinon la partie en cours (voir [displayNamesProvider]).
///
/// À appeler dans un `build`, l'écran se redessine alors quand les fiches
/// changent (un surnom modifié, une fiche supprimée).
Map<String, String> watchDisplayNames(WidgetRef ref, SavedGame? record) {
  if (record == null) return ref.watch(displayNamesProvider);
  return displayNamesFor(record.setup, ref.watch(playersProvider).value);
}

/// Nom à afficher pour [name], ou [name] lui-même faute de mieux.
String displayNameOf(Map<String, String> displayNames, String name) =>
    displayNames[name] ?? name;
