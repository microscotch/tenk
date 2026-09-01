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
}
