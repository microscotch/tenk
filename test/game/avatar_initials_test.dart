import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/avatar_initials.dart';

void main() {
  test('la lettre est la première du nom, quel que soit le nombre de mots', () {
    expect(avatarLetterFor('Marie Curie'), 'M');
    expect(avatarLetterFor('Jean Paul Sartre'), 'J');
    expect(avatarLetterFor('Bob'), 'B');
    expect(avatarLetterFor('A'), 'A');
  });

  test('espaces en bordure ignorés', () {
    expect(avatarLetterFor('  Marie   Curie  '), 'M');
  });

  test('nom vide ou uniquement des espaces : "?"', () {
    expect(avatarLetterFor(''), '?');
    expect(avatarLetterFor('   '), '?');
  });

  test('accents et casse : la lettre est toujours en majuscule', () {
    expect(avatarLetterFor('éric dupont'), 'É');
  });

  test('un emoji n\'est jamais coupé en deux : le texte reste de l\'UTF-16 bien formé', () {
    for (final name in ['🎲Lolo', '🎲 🎲', '🎲']) {
      final letter = avatarLetterFor(name);
      // Une moitié de paire de substitution isolée n'est pas un point de code valide.
      expect(letter.runes.every((r) => r < 0xD800 || r > 0xDFFF), isTrue, reason: name);
      expect(letter, '🎲');
    }
  });

  test('un caractère garde ce qui s\'y attache : teinte de peau, sélecteur d\'emoji, drapeau, accent combinant', () {
    expect(avatarLetterFor('👍🏽 Bob'), '👍🏽', reason: 'la teinte de peau reste avec son pouce');
    expect(avatarLetterFor('❤️ Lolo'), '❤️', reason: 'le sélecteur d\'emoji reste avec son cœur');
    expect(avatarLetterFor('🇫🇷 Lolo'), '🇫🇷', reason: 'un drapeau, ce sont deux moitiés');
    expect(avatarLetterFor('éric dupont'), 'É', reason: 'un accent combinant suit sa lettre');
  });

  test('une initiale reste une seule lettre : « ß » ne devient pas « SS »', () {
    expect(avatarLetterFor('ßa'), 'ß');
  });
}
