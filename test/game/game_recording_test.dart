import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';

import '../test_helpers/scripted_game.dart';

void main() {
  test('rejouer le journal depuis la seed reproduit exactement le même état final', () {
    const seed = 20260901;
    const setup = GameSetup(playerNames: ['A', 'B', 'C']);

    final played = playScriptedGame(setup, seed);
    final replay = replayGame(setup, seed, played.actions);

    expect(replay.engine, isNotNull);
    final live = played.engine;
    final replayedEngine = replay.engine!;

    expect(replayedEngine.gameOver, live.gameOver);
    expect(replayedEngine.winnerIndex, live.winnerIndex);
    expect(replayedEngine.currentPlayerIndex, live.currentPlayerIndex);
    expect(replayedEngine.players.length, live.players.length);

    for (var i = 0; i < live.players.length; i++) {
      expect(replayedEngine.players[i].name, live.players[i].name, reason: 'nom joueur $i');
      expect(replayedEngine.players[i].totalScore, live.players[i].totalScore, reason: 'score joueur $i');
      expect(replayedEngine.players[i].hasEntered, live.players[i].hasEntered, reason: 'hasEntered joueur $i');
      expect(
        replayedEngine.players[i].grid.map((e) => (e.value, e.hasTiret, e.isBarred)).toList(),
        live.players[i].grid.map((e) => (e.value, e.hasTiret, e.isBarred)).toList(),
        reason: 'grille joueur $i',
      );
    }
  });

  test('deux seeds différentes produisent des tirages différents (le test précédent teste bien quelque chose)', () {
    const setup = GameSetup(playerNames: ['A', 'B']);
    final a = playScriptedGame(setup, 111).engine;
    final b = playScriptedGame(setup, 222).engine;

    // Pas garanti à 100% en théorie (deux seeds pourraient coïncidentellement
    // produire la même issue), mais extrêmement improbable sur une partie
    // complète : sert surtout à détecter une seed ignorée par erreur (auquel
    // cas les deux résultats seraient toujours strictement identiques).
    final samePlayerScores = List.generate(setup.playerNames.length, (i) => a.players[i].totalScore).toString() ==
        List.generate(setup.playerNames.length, (i) => b.players[i].totalScore).toString();
    expect(samePlayerScores, isFalse);
  });

  test(
      'reprendre une partie à mi-chemin (journal partiel) puis continuer avec le Random du rejeu '
      "ne répète jamais un tirage déjà consommé par le rejeu", () {
    const seed = 20260901;
    const setup = GameSetup(playerNames: ['A', 'B']);

    // Journal complet d'une partie de référence, pour en extraire un
    // journal PARTIEL représentatif d'une sauvegarde en cours de tour.
    final full = playScriptedGame(setup, seed).actions;
    final cut = full.length ~/ 2;
    final partialActions = full.sublist(0, cut);

    final replay = replayGame(setup, seed, partialActions);
    expect(replay.engine, isNotNull, reason: 'le découpage doit tomber après la résolution du départage');

    // Ce que ferait GameNotifier après reprise : continuer à consommer
    // replay.random (pas un Random(seed) frais) pour les lancers suivants.
    final continued = List.generate(8, (_) => replay.random.nextInt(6));

    // Un Random(seed) frais reproduirait exactement le tout début de la
    // seed : si la reprise utilisait par erreur un Random(seed) neuf plutôt
    // que replay.random, cette séquence serait identique (probabilité de
    // coïncidence sur 8 valeurs : 6⁻⁸, négligeable).
    final fresh = Random(seed);
    final freshSequence = List.generate(8, (_) => fresh.nextInt(6));
    expect(continued, isNot(equals(freshSequence)));
  });
}
