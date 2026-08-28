import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';

void main() {
  test('un tour réussi ajoute les points et marque l\'entrée en jeu', () {
    const p = Player(name: 'A');
    final after = p.applySuccessfulTurn(500);
    expect(after.totalScore, 500);
    expect(after.hasEntered, isTrue);
  });

  test('un premier craque marque un tiret sans changer le score', () {
    final p = Player(name: 'A', totalScore: 700, hasEntered: true).applyBust();
    expect(p.totalScore, 700);
    expect(p.hasTiret, isTrue);
    expect(p.preTiretScore, 700);
  });

  test('le tiret persiste même après un tour réussi entre-temps', () {
    var p = Player(name: 'A', totalScore: 700, hasEntered: true).applyBust();
    p = p.applySuccessfulTurn(300); // tour réussi, le tiret ne s'efface pas
    expect(p.hasTiret, isTrue);
    expect(p.totalScore, 1000);
    expect(p.preTiretScore, 700);
  });

  test('un second craque barre le score et revient au dernier score non barré', () {
    var p = Player(name: 'A', totalScore: 700, hasEntered: true).applyBust();
    p = p.applySuccessfulTurn(300); // 1000, tiret toujours actif
    p = p.applyBust(); // 2e craque : barré, retour à 700
    expect(p.totalScore, 700);
    expect(p.hasTiret, isFalse);
    expect(p.preTiretScore, isNull);
  });

  test('après un score barré, un nouveau cycle de tiret peut démarrer', () {
    var p = Player(name: 'A', totalScore: 700, hasEntered: true).applyBust();
    p = p.applyBust(); // barré, retour à 700
    p = p.applyBust(); // nouveau cycle : tiret à nouveau
    expect(p.hasTiret, isTrue);
    expect(p.totalScore, 700);
    expect(p.preTiretScore, 700);
  });
}
