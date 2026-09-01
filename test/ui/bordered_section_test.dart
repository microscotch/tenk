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
}
