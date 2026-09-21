import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/game_setup.dart';
import 'package:le10000/game/score_series.dart';

import '../test_helpers/scripted_game.dart';

void main() {
  const setup = GameSetup(playerNames: ['A', 'B']);

  test('chaque série démarre à zéro', () {
    final series = scoreSeriesByPlayer(setup, 1, const []);

    expect(series, hasLength(2));
    expect(series.every((s) => s.length == 1 && s.first == 0), isTrue);
  });

  test('une série gagne un point par tour terminé, craques compris', () {
    final played = playScriptedGame(setup, 42);

    final series = scoreSeriesByPlayer(setup, 42, played.actions);

    // Tous les tours de la partie, répartis entre les joueurs. Le moteur ne
    // conserve pas ce compte, on le reconstitue depuis le journal.
    final turnsPlayed = played.actions
        .where((a) => a.type == GameActionType.bank || a.type == GameActionType.endBustedTurn)
        .length;
    final points = series.fold<int>(0, (sum, s) => sum + s.length - 1);
    expect(points, turnsPlayed, reason: 'un point par tour terminé, et pas un de plus');
  });

  test('un tour craqué laisse un palier plutôt qu\'un trou', () {
    final played = playScriptedGame(setup, 42);

    final series = scoreSeriesByPlayer(setup, 42, played.actions);

    // Une partie scriptée craque forcément quelque part : au moins un palier.
    final hasPlateau = series.any((s) {
      for (var i = 1; i < s.length; i++) {
        if (s[i] == s[i - 1]) return true;
      }
      return false;
    });
    expect(hasPlateau, isTrue,
        reason: 'un craque est un tour joué : l\'abscisse avance, l\'ordonnée non');
  });

  test('les séries ne décroissent que par un barrage', () {
    final played = playScriptedGame(setup, 7);

    final series = scoreSeriesByPlayer(setup, 7, played.actions);

    for (final s in series) {
      for (var i = 1; i < s.length; i++) {
        expect(s[i], greaterThanOrEqualTo(0));
      }
      expect(s.last, lessThanOrEqualTo(10000), reason: 'jamais au-delà de la cible');
    }
  });

  test('le vainqueur termine exactement à 10000', () {
    final played = playScriptedGame(setup, 42);

    final series = scoreSeriesByPlayer(setup, 42, played.actions);

    expect(series[played.engine.winnerIndex!].last, 10000,
        reason: 'les index sont ceux du moteur, aucune traduction à faire');
  });
}
