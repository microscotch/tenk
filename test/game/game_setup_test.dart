import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/ai/ai_profiles.dart';
import 'package:le10000/game/game_setup.dart';

void main() {
  group('rotated', () {
    test('réindexe les identifiants de fiche comme les IA et les auto', () {
      const setup = GameSetup(
        playerNames: ['A', 'B', 'C'],
        aiPlayers: {2: AiDifficulty.prudent},
        autoPlayers: {2},
        playerIds: {0: 'id-a', 1: 'id-b'},
      );

      final rotated = setup.rotated(1);

      expect(rotated.playerNames, ['B', 'C', 'A'], reason: 'B a gagné le départage');
      expect(rotated.playerIds, {2: 'id-a', 0: 'id-b'},
          reason: 'chaque fiche suit son joueur, comme le drapeau IA suit le sien');
      expect(rotated.aiPlayers.keys, [1], reason: 'C est passé du siège 2 au siège 1');
      expect(rotated.autoPlayers, {1});
    });

    test('une rotation nulle ne change rien', () {
      const setup = GameSetup(playerNames: ['A', 'B'], playerIds: {1: 'id-b'});

      expect(setup.rotated(0).playerIds, {1: 'id-b'});
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
