import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/avatar_initials.dart';

void main() {
  test('nom à 2 mots : première lettre de chacun', () {
    expect(avatarInitialsFor('Marie Curie'), 'MC');
  });

  test('nom à 3 mots ou plus : première lettre des 2 premiers seulement', () {
    expect(avatarInitialsFor('Jean Paul Sartre'), 'JP');
  });

  test('nom à 1 seul mot : première et dernière lettre du mot', () {
    expect(avatarInitialsFor('Bob'), 'BB');
    expect(avatarInitialsFor('Zaphod'), 'ZD');
  });

  test('nom à 1 seule lettre : la même lettre répétée', () {
    expect(avatarInitialsFor('A'), 'AA');
  });

  test('espaces multiples ou en bordure sont ignorés', () {
    expect(avatarInitialsFor('  Marie   Curie  '), 'MC');
  });

  test('nom vide ou uniquement des espaces : "??"', () {
    expect(avatarInitialsFor(''), '??');
    expect(avatarInitialsFor('   '), '??');
  });

  test('accents et casse : initiales toujours en majuscules', () {
    expect(avatarInitialsFor('éric dupont'), 'ÉD');
  });

  test('un emoji n\'est jamais coupé en deux : le texte reste de l\'UTF-16 bien formé', () {
    for (final name in ['Lolo🎲', 'Lolo 🎲', '🎲Lolo', '🎲 🎲', '🎲']) {
      final initials = avatarInitialsFor(name);
      // Une moitié de paire de substitution isolée n'est pas un point de code valide.
      expect(initials.runes.every((r) => r < 0xD800 || r > 0xDFFF), isTrue, reason: name);
    }
    expect(avatarInitialsFor('Lolo🎲'), 'L🎲');
    expect(avatarInitialsFor('🎲 Lolo'), '🎲L');
  });

  test('un caractère garde ce qui s\'y attache : teinte de peau, sélecteur d\'emoji, drapeau, accent combinant', () {
    expect(avatarInitialsFor('Bob👍🏽'), 'B👍🏽', reason: 'la teinte de peau reste avec son pouce');
    expect(avatarInitialsFor('Lolo❤️'), 'L❤️', reason: 'le sélecteur d\'emoji reste avec son cœur');
    expect(avatarInitialsFor('🇫🇷 Lolo'), '🇫🇷L', reason: 'un drapeau, ce sont deux moitiés');
    expect(avatarInitialsFor('Lolo🇫🇷'), 'L🇫🇷');
    expect(avatarInitialsFor('e\u0301ric dupont'), 'E\u0301D', reason: 'un accent combinant suit sa lettre');
  });

  test('une initiale reste une seule lettre : « ß » ne devient pas « SS »', () {
    expect(avatarInitialsFor('ßa'), 'ßA');
  });
}
