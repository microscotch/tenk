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
}
