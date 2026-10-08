import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/rules_screen.dart';
import 'package:le10000/ui/screens/tutorial_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_game_save_store.dart';

/// Le tutoriel sur le vrai écran de jeu : bulles, commandes qui ne répondent
/// qu'à leur étape, et rien qui subsiste une fois sorti.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ProviderContainer container;
  late FakeGameSaveStore saved;

  Future<void> open(WidgetTester tester, {Widget? next}) async {
    saved = FakeGameSaveStore();
    container = ProviderContainer(
      overrides: [
        gameSaveStoreProvider.overrideWithValue(saved),
        archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      ],
    );
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
    await tester.pump();
    await tester.pump();
  }

  /// Laisse les dés finir de rouler : la bulle n'apparaît qu'ensuite.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// La bulle affichée, et non le journal de la partie qui peut citer les mêmes mots.
  Finder bubble(String contains) => find.byWidgetPredicate(
    (w) => w is Text && w.key == const ValueKey('tutorial-text') && (w.data ?? '').contains(contains),
  );

  testWidgets('parcours complet : chaque bulle, sur la vraie commande, jusqu\'à l\'encaissement', (tester) async {
    await open(tester);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(bubble('Bienvenue'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await settle(tester);
    expect(bubble('bouton de lancer'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await settle(tester);
    expect(bubble('la main vaut 150'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await settle(tester);
    expect(bubble('main pleine'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await settle(tester);
    // Deux 5 : le sélecteur est la commande à toucher, tant qu'on n'en garde pas 1.
    final keepOne = container.read(gameProvider)!.activeTurn!.pendingRoll!.faces;
    expect(keepOne, [5, 5, 2, 3, 6]);
    expect(bubble('Choisissez 1'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1').last);
    await settle(tester);
    expect(bubble('500 points : assez'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.front_hand));
    await settle(tester);
    expect(bubble('500 points encaissés'), findsOneWidget);
    expect(container.read(gameProvider)!.players.first.totalScore, 500);
    expect(find.text('Passer'), findsNothing);

    await tester.ensureVisible(find.byKey(const ValueKey('tutorial-action')));
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
    expect(container.read(gameProvider), isNull);
  });

  testWidgets('seule la commande de l\'étape répond : Stop et le menu sont inertes', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await settle(tester);

    // Étape « lancer » : toucher Stop (inerte, et absorbé) ne change rien.
    await tester.tap(find.byIcon(Icons.front_hand), warnIfMissed: false);
    await tester.pump();
    expect(container.read(gameProvider)!.activeTurn!.pendingRoll, isNull);
    expect(find.byIcon(Icons.menu), findsNothing, reason: 'pas de menu pendant le tutoriel');
  });

  testWidgets('rien n\'est sauvegardé ni archivé, et « Passer » rend un notifier vide', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await settle(tester);
    await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
    await settle(tester);

    expect(container.read(gameProvider.notifier).seed, isNull);
    expect(container.read(gameProvider.notifier).hasLiveLocalGame, isTrue);
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(gameProvider), isNull);
    expect(container.read(gameProvider.notifier).hasLiveLocalGame, isFalse);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
    // Ni sauvegarde en cours ni archive : le tutoriel n'est pas une partie.
    expect(await saved.list(), isEmpty);
  });

  testWidgets('avec une page suivante, passer la remplace ; le retour système passe aussi', (tester) async {
    await open(tester, next: const Scaffold(body: Text('suite')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('suite'), findsOneWidget);
    expect(find.byType(TutorialScreen), findsNothing);
  });

  testWidgets('« Revoir le tutoriel » n\'est offert que depuis l\'accueil, pas depuis une partie', (tester) async {
    Future<void> pumpRules({required bool fromHome}) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: RulesScreen(canReplayTutorial: fromHome),
          ),
        ),
      );
    }

    await pumpRules(fromHome: true);
    expect(find.text('Revoir le tutoriel'), findsOneWidget);
    await pumpRules(fromHome: false);
    expect(find.text('Revoir le tutoriel'), findsNothing);
  });
}
