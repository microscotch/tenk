import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  testWidgets('un rollToken déclenche l\'animation de lancer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DieWidget(value: 4, state: DieVisualState.kept, rollToken: 'roll-1'),
      ),
    );
    await tester.pump();

    // En plein milieu de l'animation, le dé doit être visuellement en train
    // de tourner (angle non nul), pas déjà figé sur sa valeur finale.
    await tester.pump(const Duration(milliseconds: 200));
    final rotate = tester.widget<Transform>(find.byType(Transform).first);
    expect(rotate.transform.getRotation().entry(0, 1), isNot(0));

    await tester.pumpAndSettle();
  });

  testWidgets('le même rollToken ne rejoue pas l\'animation lors d\'un simple changement de state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DieWidget(value: 5, state: DieVisualState.kept, rollToken: 'roll-A'),
      ),
    );
    await tester.pumpAndSettle();
    final restRotation = tester.widget<Transform>(find.byType(Transform).first).transform.getRotation().entry(0, 1);

    // Un changement de sélection (kept -> declined) sans nouveau lancer ne
    // doit pas relancer l'animation : l'inclinaison de repos reste la même.
    await tester.pumpWidget(
      const MaterialApp(
        home: DieWidget(value: 5, state: DieVisualState.declined, rollToken: 'roll-A'),
      ),
    );
    await tester.pump();

    final rotate = tester.widget<Transform>(find.byType(Transform).first);
    expect(rotate.transform.getRotation().entry(0, 1), restRotation);
  });

  testWidgets('sans rollToken, le dé reste directement sur son inclinaison de repos (pas d\'animation)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DieWidget(value: 3, state: DieVisualState.kept),
      ),
    );
    final atFirstFrame = tester.widget<Transform>(find.byType(Transform).first).transform.getRotation().entry(0, 1);

    await tester.pump(const Duration(milliseconds: 100));
    final afterDelay = tester.widget<Transform>(find.byType(Transform).first).transform.getRotation().entry(0, 1);

    // Aucune animation en cours : l'inclinaison ne bouge pas entre les deux.
    expect(afterDelay, atFirstFrame);
  });
}
