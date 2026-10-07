import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/tutorial.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/tutorial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pumpTutorial(WidgetTester tester, {Widget? next}) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TutorialScreen(next: next))),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('le tutoriel se joue jusqu\'au bout puis se referme, marqué comme vu', (tester) async {
    final container = await pumpTutorial(tester);
    for (var i = 0; i < tutorialSteps.length - 1; i++) {
      await tester.tap(find.byKey(const ValueKey('tutorial-action')));
      await tester.pump(const Duration(seconds: 2));
    }
    expect(find.text('Commencer à jouer'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
  });

  testWidgets('« Passer » quitte à tout moment et compte comme vu', (tester) async {
    final container = await pumpTutorial(tester);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
  });

  testWidgets('avec une page suivante, passer la remplace', (tester) async {
    await pumpTutorial(tester, next: const Scaffold(body: Text('suite')));
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.text('suite'), findsOneWidget);
    expect(find.byType(TutorialScreen), findsNothing);
  });
}
