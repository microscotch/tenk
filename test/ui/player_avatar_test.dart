import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/avatar_catalog.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

void main() {
  testWidgets('affiche la première lettre du nom du joueur', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PlayerAvatarWidget(name: 'Marie Curie'))),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('un animal remplace la lettre', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PlayerAvatarWidget(name: 'Marie Curie', animal: 'fox'))),
    );

    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('M'), findsNothing);
  });

  testWidgets('un animal inconnu retombe sur la lettre', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PlayerAvatarWidget(name: 'Marie Curie', animal: 'dragon'))),
    );

    expect(find.text('M'), findsOneWidget);
  });

  testWidgets('deux joueurs de noms différents ont des couleurs de blason différentes', (tester) async {
    // 'A' et 'B' tombent sur des index différents dans la palette
    // (somme des code units différente) : les deux CustomPaint doivent donc
    // recevoir des Paint de couleurs différentes.
    expect(avatarColorFor('A'), isNot(avatarColorFor('B')));
  });

  testWidgets('même nom : même couleur (déterministe)', (tester) async {
    expect(avatarColorFor('Marie Curie'), avatarColorFor('Marie Curie'));
  });

  test('la couleur choisie dans un profil l\'emporte, et personne d\'autre ne la reçoit', () {
    const names = ['Alice', 'Bob', 'Chloe'];
    final colors = assignAvatarColors(names, looks: {'Chloe': const AvatarLook(color: 'teal')});

    expect(colors['Chloe'], const Color(0xFF2E8B8B));
    expect(colors.values.toSet().length, names.length, reason: 'aucune couleur en double');
  });

  test('deux joueurs qui choisissent la même couleur : le premier la garde, le second retombe sur une attribuée', () {
    final colors = assignAvatarColors(
      ['Alice', 'Bob'],
      looks: {'Alice': const AvatarLook(color: 'rose'), 'Bob': const AvatarLook(color: 'rose')},
    );

    expect(colors['Alice'], const Color(0xFFB84F78));
    expect(colors['Bob'], isNot(colors['Alice']));
  });

  test('un identifiant de couleur inconnu se lit comme pas de choix', () {
    final colors = assignAvatarColors(['Alice'], looks: {'Alice': const AvatarLook(color: 'mauve-fluo')});

    expect(colors['Alice'], avatarColorFor('Alice'));
  });

  test(
    'assignAvatarColors résout les collisions de hash : jamais deux joueurs '
    'de la même partie avec la même couleur de blason',
    () {
      // Bob/Chloe/Dan tombent sur le même index naïf, Eve/Farid sur un
      // autre : un cas de collision multiple, avec exactement 6 joueurs
      // pour une palette de 12 couleurs — vérifie
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
