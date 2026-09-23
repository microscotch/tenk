import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/game_setup.dart';

void main() {
  group('reordered', () {
    const setup = GameSetup(
      playerNames: ['A', 'B', 'C'],
      aiPlayers: {2: AiDifficulty.prudent},
      autoPlayers: {2},
      playerIds: {0: 'id-a', 1: 'id-b'},
    );

    test('dans le sens de la liste, réindexe les fiches comme les IA et les auto', () {
      final ordered = setup.reordered([1, 2, 0]);

      expect(ordered.playerNames, ['B', 'C', 'A'], reason: 'B a gagné le départage');
      expect(ordered.playerIds, {2: 'id-a', 0: 'id-b'},
          reason: 'chaque fiche suit son joueur, comme le drapeau IA suit le sien');
      expect(ordered.aiPlayers.keys, [1], reason: 'C est passé du siège 2 au siège 1');
      expect(ordered.autoPlayers, {1});
    });

    test('à rebours, chaque joueur garde aussi sa fiche et ses drapeaux', () {
      final ordered = setup.reordered([1, 0, 2]);

      expect(ordered.playerNames, ['B', 'A', 'C']);
      expect(ordered.playerIds, {1: 'id-a', 0: 'id-b'});
      expect(ordered.aiPlayers.keys, [2]);
      expect(ordered.autoPlayers, {2});
    });

    test('l\'ordre identité ne change rien', () {
      const two = GameSetup(playerNames: ['A', 'B'], playerIds: {1: 'id-b'});

      expect(two.reordered([0, 1]).playerIds, {1: 'id-b'});
    });
  });

  test('un siège sans fiche se lit comme non rattaché', () {
    const setup = GameSetup(playerNames: ['A', 'Bot'], playerIds: {0: 'id-a'});

    expect(setup.playerIdAt(0), 'id-a');
    expect(setup.playerIdAt(1), isNull, reason: 'un bot n\'a pas de fiche');
  });

  test('une config sans aucun identifiant reste valide', () {
    const setup = GameSetup(playerNames: ['A', 'B']);

    expect(setup.playerIds, isEmpty);
    expect(setup.playerIdAt(0), isNull);
  });
}
