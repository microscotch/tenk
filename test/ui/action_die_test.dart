import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/widgets/menu_die.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

ActionDie _die({VoidCallback? onPressed}) => ActionDie.uniform(
      kind: ActionDieKind.stop,
      mark: const DieMark.icon(Icons.attach_money),
      color: Colors.amber,
      ink: Colors.white,
      size: 48,
      tooltip: 'Stop',
      onPressed: onPressed,
    );

void main() {
  testWidgets('un dé d\'action actif s\'active au lecteur d\'écran', (tester) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(_host(_die(onPressed: () => taps++)));

    final node = tester.getSemantics(find.bySemanticsLabel('Stop'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    tester.semantics.tap(find.semantics.byLabel('Stop'));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('un dé d\'action inerte n\'offre aucune action', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(_die()));

    final data = tester.getSemantics(find.bySemanticsLabel('Stop')).getSemanticsData();
    expect(data.hasAction(SemanticsAction.tap), isFalse);
    handle.dispose();
  });

  testWidgets('un dé marqué d\'un émoji se dessine, faces visibles et cachées', (tester) async {
    await tester.pumpWidget(_host(const ActionDie.uniform(
      kind: ActionDieKind.observed,
      mark: DieMark.emoji('💥'),
      color: Colors.grey,
      ink: Colors.white,
      size: 48,
      caption: 'Craqué !',
    )));
    // L'image du dé est calculée hors de l'horloge factice du test.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    expect(find.byType(RawImage), findsOneWidget);
    expect(find.text('Craqué !'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('deux marques émoji ne se confondent que sur le même émoji', () {
    expect(const DieMark.emoji('💥'), const DieMark.emoji('💥'));
    expect(const DieMark.emoji('💥'), isNot(const DieMark.emoji('💣')));
  });
}
