import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

void main() {
  testWidgets('affiche les initiales calculées pour le nom du joueur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PlayerAvatarWidget(name: 'Marie Curie'))),
    );

    expect(find.text('MC'), findsOneWidget);
  });

  testWidgets('deux joueurs de noms différents ont des couleurs de blason différentes', (tester) async {
    // 'A' et 'B' tombent sur des index différents dans kAvatarColorPalette
    // (somme des code units différente) : les deux CustomPaint doivent donc
    // recevoir des Paint de couleurs différentes.
    expect(avatarColorFor('A'), isNot(avatarColorFor('B')));
  });

  testWidgets('même nom : même couleur (déterministe)', (tester) async {
    expect(avatarColorFor('Marie Curie'), avatarColorFor('Marie Curie'));
  });

  test(
    'assignAvatarColors résout les collisions de hash : jamais deux joueurs '
    'de la même partie avec la même couleur de blason',
    () {
      // Bob/Chloe/Dan tombent sur le même index naïf, Eve/Farid sur un
      // autre : un cas de collision multiple, avec exactement 6 joueurs
      // pour une palette de 6 couleurs (voir kAvatarColorPalette) — vérifie
      // que la résolution circulaire couvre bien toute la palette.
      const names = ['Alice', 'Bob', 'Chloe', 'Dan', 'Eve', 'Farid'];
      final colors = assignAvatarColors(names);

      expect(colors.length, names.length);
      expect(colors.values.toSet().length, names.length, reason: 'chaque joueur doit avoir une couleur distincte');
    },
  );

  test('assignAvatarColors reste déterministe pour un même ordre de joueurs', () {
    const names = ['Alice', 'Bob', 'Chloe', 'Dan', 'Eve', 'Farid'];
    expect(assignAvatarColors(names), assignAvatarColors(names));
  });
}
