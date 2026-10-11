import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/tutorial.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/rules_screen.dart';
import 'package:le10000/ui/screens/tutorial_screen.dart';
import 'package:le10000/ui/widgets/tutorial_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_game_save_store.dart';

/// Le tutoriel sur le vrai écran de jeu : chaque leçon jouée comme un joueur
/// qui suit les bulles, jusque dans les fenêtres de craque et de main héritée.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late ProviderContainer container;
  late FakeGameSaveStore saved;

  Future<void> open(WidgetTester tester, {Widget? next, TutorialLessonId? lesson}) async {
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
                onPressed: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => TutorialScreen(next: next, lesson: lesson))),
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
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// L'étape dont la bulle est affichée, retrouvée par son texte ; null sans bulle.
  String? shownBeat(WidgetTester tester) {
    final texts = find.byKey(const ValueKey('tutorial-text'));
    if (texts.evaluate().isEmpty) return null;
    final text = tester.widget<Text>(texts.last).data;
    final guide = tester.widget<GameScreen>(find.byType(GameScreen)).tutorial!;
    final l10n = AppLocalizations.of(tester.element(find.byType(GameScreen)));
    for (final beat in guide.lesson.beats) {
      if (tutorialBeatText(l10n, guide.lesson.id, beat.id) == text) return beat.id;
    }
    fail('texte de bulle inconnu : $text');
  }

  TutorialBeat beatNamed(WidgetTester tester, String id) =>
      tester.widget<GameScreen>(find.byType(GameScreen)).tutorial!.lesson.beats.firstWhere((b) => b.id == id);

  /// Joue la leçon à l'écran en suivant les bulles, jusqu'à sa conclusion
  /// (comprise) : rend les étapes vues.
  Future<List<String>> playLesson(WidgetTester tester) async {
    final seen = <String>[];
    for (var i = 0; i < 200; i++) {
      final id = shownBeat(tester);
      if (id == null) {
        await tester.pump(const Duration(milliseconds: 250));
        continue;
      }
      if (seen.isEmpty || seen.last != id) seen.add(id);
      final beat = beatNamed(tester, id);
      if (beat.isOutro) return seen;
      if (beat.needsAck) {
        await tester.tap(find.byKey(const ValueKey('tutorial-action')).last);
      } else {
        switch (beat.target) {
          case TutorialTarget.roll:
            await tester.tap(find.widgetWithIcon(FilledButton, Icons.casino));
          case TutorialTarget.stop:
            await tester.tap(find.byIcon(Icons.front_hand));
          case TutorialTarget.exchange:
            await tester.tap(find.byType(DropdownButton<int>));
            await tester.pumpAndSettle();
            await tester.tap(find.text('1').last);
          case TutorialTarget.bustOk:
            await tester.tap(find.byTooltip('Continuer'));
          case TutorialTarget.inheritTake:
            await tester.tap(find.byTooltip('Reprendre la main'));
          case TutorialTarget.opponentRow:
          case TutorialTarget.finalBanner:
          case null:
            break; // le bot joue, ou le 10 000 se prend seul : on attend
        }
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    fail('leçon jamais finie : $seen');
  }

  testWidgets('tout le parcours : sept leçons, chaque bulle sur la vraie commande, puis la fin', (tester) async {
    await open(tester);
    final expected = {
      TutorialLessonId.basics: ['intro', 'roll', 'ace', 'brelan', 'outro'],
      TutorialLessonId.hotDice: ['intro', 'roll', 'kept', 'fullHand', 'fives', 'stop', 'outro'],
      TutorialLessonId.bust: ['intro', 'roll', 'tiret', 'botTurn', 'rollAgain', 'barred', 'outro'],
      TutorialLessonId.extension: ['intro', 'roll', 'brelan', 'extended', 'outro'],
      TutorialLessonId.inheritedHand: ['intro', 'botTurn', 'take', 'stop', 'outro'],
      TutorialLessonId.collision: ['intro', 'roll', 'collide', 'outro'],
      TutorialLessonId.finalRound: ['intro', 'roll', 'noStop', 'exact', 'outro'],
    };
    for (final (i, lesson) in tutorialLessons.indexed) {
      final guide = tester.widget<GameScreen>(find.byType(GameScreen)).tutorial!;
      expect(guide.lesson.id, lesson.id);
      expect(find.textContaining('Leçon ${i + 1}/7'), findsOneWidget);
      expect(await playLesson(tester), expected[lesson.id], reason: '${lesson.id}');
      final last = i == tutorialLessons.length - 1;
      expect(find.text(last ? 'Commencer à jouer' : 'Leçon suivante'), findsOneWidget);
      expect(find.text('Passer'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tutorial-action')).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
    expect(container.read(gameProvider), isNull);
    expect(await saved.list(), isEmpty, reason: 'rien n\'est sauvegardé');
  });

  testWidgets('une leçon seule (depuis la liste) se termine sur « Commencer à jouer »', (tester) async {
    await open(tester, lesson: TutorialLessonId.collision);
    expect(find.textContaining('Leçon 6/7'), findsOneWidget);
    expect(await playLesson(tester), ['intro', 'roll', 'collide', 'outro']);
    expect(find.text('Commencer à jouer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')).last);
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
  });

  testWidgets('seule la commande de l\'étape répond : Stop et le menu sont inertes', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('tutorial-action')));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.byIcon(Icons.front_hand), warnIfMissed: false);
    await tester.pump();
    expect(container.read(gameProvider)!.activeTurn!.pendingRoll, isNull);
    expect(find.byIcon(Icons.menu), findsNothing, reason: 'pas de menu pendant le tutoriel');
  });

  testWidgets('« Passer » rend un notifier vide et compte comme vu', (tester) async {
    await open(tester);
    expect(container.read(gameProvider.notifier).seed, isNull);
    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialScreen), findsNothing);
    expect(container.read(gameProvider), isNull);
    expect(container.read(gameProvider.notifier).hasLiveLocalGame, isFalse);
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
  });

  testWidgets('avec une page suivante, le retour système passe et la remplace', (tester) async {
    await open(tester, next: const Scaffold(body: Text('suite')));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('suite'), findsOneWidget);
    expect(find.byType(TutorialScreen), findsNothing);
  });

  testWidgets('les leçons ne s\'ouvrent que depuis l\'accueil, et se rejouent une à une', (tester) async {
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

    await pumpRules(fromHome: false);
    expect(find.text('Leçons du tutoriel'), findsNothing);
    await pumpRules(fromHome: true);
    await tester.tap(find.text('Leçons du tutoriel'));
    await tester.pumpAndSettle();
    expect(find.byType(TutorialLessonsScreen), findsOneWidget);
    expect(find.text('Tout le parcours'), findsOneWidget);
    for (final title in ['Les bases', 'La main pleine', 'Le craque', 'L\'extension', 'La main héritée', 'Barrer un joueur', 'Le dernier tour']) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
  });
}
