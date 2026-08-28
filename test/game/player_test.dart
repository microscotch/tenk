import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';

void main() {
  test('un tour réussi ajoute les points, marque l\'entrée et mémorise le score précédent', () {
    const p = Player(name: 'A');
    final after = p.applySuccessfulTurn(500);
    expect(after.totalScore, 500);
    expect(after.hasEntered, isTrue);
    expect(after.previousScore, 0);
  });

  test('un premier craque marque un tiret sans changer le score', () {
    var p = const Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust();
    expect(p.totalScore, 700);
    expect(p.hasTiret, isTrue);
    expect(p.previousScore, 0); // point de retour = score d'avant ce tour de 700
  });

  test('le tiret persiste après un tour réussi entre-temps, et le point de retour se met à jour', () {
    var p = const Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret posé, point de retour = 0
    p = p.applySuccessfulTurn(300); // 700 -> 1000, point de retour mis à jour à 700
    expect(p.hasTiret, isTrue);
    expect(p.totalScore, 1000);
    expect(p.previousScore, 700);
  });

  test('un second craque barre le score d\'un seul cran (pas jusqu\'au point du tiret)', () {
    var p = const Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret posé, point de retour = 0
    p = p.applySuccessfulTurn(300); // 700 -> 1000, point de retour = 700
    p = p.applyBust(); // 2e craque : barré -> revient à 700, PAS à 0
    expect(p.totalScore, 700);
    expect(p.hasTiret, isFalse);
  });

  test('après un score barré, un nouveau cycle de tiret peut démarrer', () {
    var p = const Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret, point de retour = 0
    p = p.applyBust(); // barré -> revient à 0, tiret effacé
    expect(p.totalScore, 0);
    expect(p.hasTiret, isFalse);

    p = p.applyBust(); // nouveau cycle : tiret à nouveau, rien à barrer de plus bas
    expect(p.hasTiret, isTrue);
    expect(p.totalScore, 0);
  });

  group('applyScoreCollisionBar', () {
    test('barre même sans tiret actif', () {
      var p = const Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applyScoreCollisionBar();
      expect(p.totalScore, 0);
      expect(p.hasTiret, isFalse);
    });

    test('barre aussi un joueur qui portait déjà un tiret, et l\'efface', () {
      var p = const Player(name: 'A').applySuccessfulTurn(500); // 0 -> 500
      p = p.applyBust(); // tiret posé, point de retour = 0
      p = p.applySuccessfulTurn(300); // 500 -> 800, point de retour = 500
      p = p.applyScoreCollisionBar(); // barre -> 500, tiret effacé
      expect(p.totalScore, 500);
      expect(p.hasTiret, isFalse);
    });
  });
}
