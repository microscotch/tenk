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

  test('un craque à 0 ne marque jamais de tiret : rien à sanctionner en dessous du plancher', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
    p = p.applyBust(); // tiret, point de retour = 0
    p = p.applyBust(); // barré -> revient à 0, tiret effacé
    expect(p.totalScore, 0);
    expect(p.hasTiret, isFalse);

    p = p.applyBust(); // craque à 0 : sans effet, jamais de tiret
    expect(p.hasTiret, isFalse);
    expect(p.totalScore, 0);
  });

  test('un barrage réutilise la ligne existante au lieu d\'en dupliquer une nouvelle', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // grid: [0, 700]
    p = p.applyBust(); // tiret sur 700
    p = p.applySuccessfulTurn(300); // grid: [0, 700(tiret), 1000]
    expect(p.grid, hasLength(3));

    p = p.applyBust(); // tiret sur 1000
    p = p.applyBust(); // 1000 barré -> retombe sur la ligne 700 déjà existante
    expect(p.grid, hasLength(3), reason: 'aucune ligne dupliquée pour le retour à 700');
    expect(p.totalScore, 700);
    expect(p.currentIndex, 1);
    expect(p.grid[1].value, 700);
    expect(p.grid[2].isBarred, isTrue, reason: 'la ligne 1000 garde son statut barré dans l\'historique');
  });

  test('un retour à 0 (barrage) remet l\'entrée en jeu à zéro : il faut de nouveau 500', () {
    var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700, hasEntered devient true
    expect(p.hasEntered, isTrue);
    p = p.applyBust(); // tiret, point de retour = 0
    p = p.applyBust(); // barré -> revient à 0
    expect(p.totalScore, 0);
    expect(p.hasEntered, isFalse, reason: 'retombé à 0 : il faut de nouveau marquer 500 pour entrer');
    expect(p.minimumForNextTurn, entryThreshold);
  });

  group('applyScoreCollisionBar', () {
    test('barre même sans tiret actif', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applyScoreCollisionBar();
      expect(p.totalScore, 0);
      expect(p.hasTiret, isFalse);
    });

    test('une collision qui ramène à 0 remet aussi l\'entrée en jeu à zéro', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applyScoreCollisionBar(); // collision -> retombe à 0
      expect(p.totalScore, 0);
      expect(p.hasEntered, isFalse);
      expect(p.minimumForNextTurn, entryThreshold);
    });

    test('une collision qui ne ramène pas à 0 ne touche pas à l\'entrée en jeu', () {
      var p = Player(name: 'A').applySuccessfulTurn(500); // 0 -> 500
      p = p.applySuccessfulTurn(300); // 500 -> 800
      p = p.applyScoreCollisionBar(); // collision -> retombe à 500, toujours entré
      expect(p.totalScore, 500);
      expect(p.hasEntered, isTrue);
      expect(p.minimumForNextTurn, normalThreshold);
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

  group('applyScoreCollisionBarAt', () {
    test('collision sur la ligne courante : comportement inchangé (repli sur le score précédent)', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applyScoreCollisionBarAt(700);
      expect(p.totalScore, 0);
      expect(p.grid.last.isBarred, isTrue);
    });

    // Régression : un adversaire qui a DÉJÀ eu 700 (avant de progresser à
    // 900) doit être barré sur cette ligne même si 700 n'est plus son score
    // courant — signalé en jeu : la collision passait inaperçue.
    test('collision sur une ligne plus ancienne déjà dépassée : seule cette ligne est barrée, le score courant ne bouge pas', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applySuccessfulTurn(200); // 700 -> 900

      p = p.applyScoreCollisionBarAt(700);

      expect(p.totalScore, 900, reason: 'la progression depuis 700 -> 900 n\'est pas remise en cause');
      expect(p.hasEntered, isTrue);
      expect(p.grid[1].value, 700);
      expect(p.grid[1].isBarred, isTrue, reason: 'la ligne 700 est barrée dans l\'historique');
      expect(p.grid[2].isBarred, isFalse, reason: 'la ligne courante (900) n\'est pas affectée');
    });

    test('aucune ligne ne correspond : sans effet', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      final unchanged = p.applyScoreCollisionBarAt(1234);
      expect(unchanged.totalScore, 700);
      expect(unchanged.grid.every((e) => !e.isBarred), isTrue);
    });

    test('une ligne déjà barrée ne peut pas l\'être une seconde fois par une nouvelle collision', () {
      var p = Player(name: 'A').applySuccessfulTurn(700); // 0 -> 700
      p = p.applySuccessfulTurn(200); // 700 -> 900
      p = p.applyScoreCollisionBarAt(700); // barre la ligne 700
      expect(p.grid[1].isBarred, isTrue);

      final again = p.applyScoreCollisionBarAt(700); // déjà barrée : sans effet
      expect(again.totalScore, 900);
      expect(again.grid[1].isBarred, isTrue);
    });
  });
}
