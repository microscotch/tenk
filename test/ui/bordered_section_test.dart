import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/bordered_section.dart';

void main() {
  testWidgets('affiche le libellé et le contenu fourni', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BorderedSection(label: 'Ma zone', child: Text('Contenu')),
        ),
      ),
    );

    expect(find.text('Ma zone'), findsOneWidget);
    expect(find.text('Contenu'), findsOneWidget);
  });

  testWidgets('le contenu occupe toute la hauteur allouée par un Expanded parent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [Expanded(child: BorderedSection(label: 'Ma zone', child: Text('Contenu')))],
          ),
        ),
      ),
    );

    final sectionSize = tester.getSize(find.byType(BorderedSection));
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(sectionSize.height, screenSize.height);
  });

  testWidgets('fillAvailableSpace: false se dimensionne à son contenu dans un Column non contraint',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              BorderedSection(fillAvailableSpace: false, label: 'Ma zone', child: Text('Contenu')),
            ],
          ),
        ),
      ),
    );

    final sectionSize = tester.getSize(find.byType(BorderedSection));
    final screenSize = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(sectionSize.height, lessThan(screenSize.height));
  });
}
