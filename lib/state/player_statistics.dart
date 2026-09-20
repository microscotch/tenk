import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_statistics.dart';
import '../game/player_profile.dart';
import '../game/player_stats.dart';
import 'game_save_store.dart';
import 'player_store.dart';

/// Amorce la base depuis les parties archivées, puis recalcule toutes les
/// statistiques. Rend le nombre de fiches créées.
///
/// **Recalcul complet, jamais incrémental.** C'est ce qui le rend idempotent
/// par construction : aucune comptabilité du genre « cette partie a déjà été
/// comptée » ne peut dériver, et le rattrapage rétroactif emprunte exactement
/// le même chemin que la mise à jour courante.
Future<int> syncPlayerStatistics({
  required GameSaveStore archive,
  required PlayerStore players,
}) async {
  final games = await archive.list();
  var created = 0;

  // Index des noms connus — nom courant ET anciens noms. C'est lui qui sert à
  // l'amorçage comme au rattachement : s'en tenir au nom courant recréerait
  // une fiche pour chaque joueur renommé, et couperait l'original de tout son
  // historique archivé.
  final profiles = <PlayerProfile>[...await players.list()];
  final idByName = <String, String>{};
  void index(PlayerProfile profile) {
    for (final name in profile.allNames) {
      idByName.putIfAbsent(normalizeName(name), () => profile.id);
    }
  }

  profiles.forEach(index);

  // Amorçage : toute personne ayant joué une partie archivée mérite sa fiche.
  // Les archives ne contiennent que des NOMS, donc c'est par eux qu'on crée —
  // et c'est aussi par eux qu'on rattachera, faute de mieux.
  for (final game in games) {
    for (var seat = 0; seat < game.setup.playerNames.length; seat++) {
      if (game.setup.isAi(seat)) continue;
      final name = game.setup.playerNames[seat];
      if (name.trim().isEmpty) continue;
      if (idByName.containsKey(normalizeName(name))) continue;
      final profile = PlayerProfile.create(name: name);
      await players.write(profile);
      profiles.add(profile);
      index(profile);
      created++;
    }
  }

  final byId = {for (final p in profiles) p.id: p};

  final totals = {for (final p in profiles) p.id: PlayerStats.empty};

  for (final game in games) {
    GameStatistics stats;
    try {
      stats = collectGameStatistics(setup: game.setup, seed: game.seed, actions: game.actions);
    } catch (_) {
      // Un journal incohérent ne doit pas vider les statistiques de toute
      // l'app : on saute cette partie, comme `GameSaveStore.list()` saute un
      // fichier illisible.
      continue;
    }

    for (var seat = 0; seat < stats.bySeat.length; seat++) {
      if (game.setup.isAi(seat)) continue;
      // L'identifiant d'abord, le nom ensuite : le lien explicite survit à un
      // renommage, le nom n'est qu'un repli pour les parties antérieures.
      final id = game.setup.playerIdAt(seat) ??
          idByName[normalizeName(game.setup.playerNames[seat])];
      if (id == null || !totals.containsKey(id)) continue;
      totals[id] = totals[id]! + stats.bySeat[seat];
    }
  }

  for (final entry in totals.entries) {
    final profile = byId[entry.key]!;
    // Remplacement, jamais addition : c'est ce qui rend un second passage
    // inoffensif.
    await players.write(profile.copyWith(stats: entry.value));
  }

  return created;
}

/// Amorçage + recalcul, une fois par session, déclenché par le premier écran
/// qui a besoin de statistiques à jour. `ref.invalidate` force un nouveau
/// passage, par exemple après qu'une partie s'est terminée.
final playerStatisticsSyncProvider = FutureProvider<int>((ref) async {
  final created = await syncPlayerStatistics(
    archive: ref.watch(archivedGameSaveStoreProvider),
    players: ref.watch(playerStoreProvider),
  );
  ref.invalidate(playersProvider);
  return created;
});
