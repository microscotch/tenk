import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/bordered_section.dart';

void main() {
  testWidgets('affiche le libellé et le contenu fourni', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorderedSection(
            label: 'Ma zone',
            isExpanded: true,
            onHeaderTap: () {},
            child: const Text('Contenu'),
          ),
        ),
      ),
    );

    expect(find.text('Ma zone'), findsOneWidget);
    expect(find.text('Contenu'), findsOneWidget);
  });

  testWidgets('le contenu reste monté (pas de perte d\'état) même fermé, mais devient invisible', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BorderedSection(
            label: 'Ma zone',
            isExpanded: false,
            onHeaderTap: () => tapped++,
            child: const Text('Contenu'),
          ),
        ),
      ),
    );

    // Monté (findsOneWidget, pas findsNothing) mais l'opacité de son
    // ancêtre AnimatedOpacity doit être nulle une fois l'animation résolue.
    expect(find.text('Contenu'), findsOneWidget);
    await tester.pumpAndSettle();
    final opacityWidget = tester.widget<AnimatedOpacity>(
      find.ancestor(of: find.text('Contenu'), matching: find.byType(AnimatedOpacity)),
    );
    expect(opacityWidget.opacity, 0);

    await tester.tap(find.text('Ma zone'));
    expect(tapped, 1);
  });
}
