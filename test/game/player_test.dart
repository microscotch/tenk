import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';

void main() {
  test('un tour réussi ajoute les points, marque l\'entrée et mémorise le score précédent', () {
    final p = Player(name: 'A');
    final after = p.applySuccessfulTurn(500);
    expect(after.totalScore, 500);
    expect(after.hasEntered, isTrue);
    expect(after.previousScore, 0);
  });

  test('un premier craque marque un tiret sans changer le score', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust();
    expect(p.totalScore, 700);
    expect(p.hasTiret, isTrue);
    expect(p.previousScore, 0); // point de retour = score d'avant ce tour de 700
  });

  test('un tour réussi après un craque repart sur une ligne propre : le trait reste sur l\'ancienne', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret posé sur la ligne 700
    p = p.applySuccessfulTurn(300); // 700 -> 1000 : nouvelle ligne, sans tiret
    expect(p.hasTiret, isFalse, reason: 'le trait reste attaché à la ligne 700, pas à la nouvelle');
    expect(p.totalScore, 1000);
    expect(p.previousScore, 700);
  });

  test('deux craques consécutifs (sans tour réussi entre eux) barrent la ligne courante', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret posé sur 700
    p = p.applySuccessfulTurn(300); // 700 -> 1000 : nouvelle ligne propre
    p = p.applyBust(); // 1er craque sur CETTE ligne (1000) : simple tiret, 700 n'est pas concerné
    expect(p.totalScore, 1000);
    expect(p.hasTiret, isTrue);

    p = p.applyBust(); // 2e craque consécutif sur 1000 : barré, retour à 700
    expect(p.totalScore, 700);
    expect(p.hasTiret, isFalse);
  });

  test('après un score barré, un nouveau cycle de tiret peut démarrer', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
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
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applyScoreCollisionBar();
      expect(p.totalScore, 0);
      expect(p.hasTiret, isFalse);
    });

    test('barre aussi un joueur qui portait déjà un tiret, et l\'efface', () {
      var p = Player(name: 'A').applySuccessfulTurn(500); // 0 -> 500
      p = p.applyBust(); // tiret posé, point de retour = 0
      p = p.applySuccessfulTurn(300); // 500 -> 800, point de retour = 500
      p = p.applyScoreCollisionBar(); // barre -> 500, tiret effacé
      expect(p.totalScore, 500);
      expect(p.hasTiret, isFalse);
    });
  });
}
