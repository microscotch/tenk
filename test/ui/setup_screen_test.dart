import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/ui/screens/finished_games_screen.dart';
import 'package:le10000/ui/screens/new_game_screen.dart';
import 'package:le10000/ui/screens/paused_games_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/scripted_game.dart';

/// L'écran d'accueil, réduit à cinq boutons : les deux listes qui s'y
/// affichaient en permanence vivent maintenant derrière le leur.
void main() {
  late FakeGameSaveStore paused;
  late FakeGameSaveStore archived;

  setUp(() {
    paused = FakeGameSaveStore();
    archived = FakeGameSaveStore();
  });

  Future<ProviderContainer> pumpHome(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        gameSaveStoreProvider.overrideWithValue(paused),
        archivedGameSaveStoreProvider.overrideWithValue(archived),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// L'accueil propose de reprendre la dernière partie interrompue dès son
  /// ouverture (comportement d'origine, conservé). Cette popup est modale :
  /// tout test qui veut cliquer sur les boutons doit d'abord la refermer.
  Future<void> dismissResumeOffer(WidgetTester tester) async {
    if (find.byType(AlertDialog).evaluate().isEmpty) return;
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
  }

  /// L'état actif/inerte se lit sur le bouton, pas sur le texte : un libellé
  /// présent ne dit rien de sa cliquabilité.
  ///
  /// Le bouton se cherche par prédicat et non par `find.byType` : celui-ci
  /// exige le type exact, alors que `FilledButton.icon`/`OutlinedButton.icon`
  /// construisent des sous-classes privées.
  bool isEnabled(WidgetTester tester, String label) {
    final button = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
      ),
    );
    return button.onPressed != null;
  }

  testWidgets('l\'accueil affiche les cinq boutons et plus aucune liste', (tester) async {
    await pumpHome(tester);

    for (final label in const [
      'Nouvelle partie',
      'Reprise de parties',
      'Gestion des joueurs',
      'Dernières parties terminées',
      'Statistiques',
    ]) {
      expect(find.text(label), findsOneWidget, reason: '$label doit être proposé');
    }
  });

  testWidgets('le bouton de reprise est inerte tant qu\'aucune partie n\'est en pause', (tester) async {
    await pumpHome(tester);

    expect(isEnabled(tester, 'Reprise de parties'), isFalse,
        reason: 'ouvrir un écran sur une liste vide n\'apprendrait rien');
    expect(isEnabled(tester, 'Nouvelle partie'), isTrue);
    expect(isEnabled(tester, 'Dernières parties terminées'), isTrue);
  });

  testWidgets('le bouton de reprise s\'active dès qu\'une partie est en pause', (tester) async {
    await paused.write(
      buildResumableSavedGame(seed: 7, alias: 'Facétieux Croupier', playerNames: const ['Marie', 'Bob']),
    );
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    expect(isEnabled(tester, 'Reprise de parties'), isTrue);
  });

  testWidgets('une partie en pause déclenche toujours la proposition de reprise', (tester) async {
    await paused.write(
      buildResumableSavedGame(seed: 7, alias: 'Facétieux Croupier', playerNames: const ['Marie', 'Bob']),
    );
    await pumpHome(tester);

    expect(find.byType(AlertDialog), findsOneWidget,
        reason: 'la refonte de l\'accueil ne doit pas avoir supprimé cette proposition');
    expect(find.textContaining('Facétieux Croupier'), findsOneWidget);
  });

  testWidgets('chaque bouton actif ouvre son écran', (tester) async {
    await paused.write(
      buildResumableSavedGame(seed: 7, alias: 'Facétieux Croupier', playerNames: const ['Marie', 'Bob']),
    );
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    await tester.tap(find.text('Reprise de parties'));
    await tester.pumpAndSettle();
    expect(find.byType(PausedGamesScreen), findsOneWidget);
    // `pageBack()` cherche l'infobulle anglaise « Back » : les tests tournent
    // en français (voir test/flutter_test_config.dart), on tape le bouton.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dernières parties terminées'));
    await tester.pumpAndSettle();
    expect(find.byType(FinishedGamesScreen), findsOneWidget);
    // `pageBack()` cherche l'infobulle anglaise « Back » : les tests tournent
    // en français (voir test/flutter_test_config.dart), on tape le bouton.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pumpAndSettle();
    expect(find.byType(NewGameScreen), findsOneWidget);
  });

  testWidgets('les deux fonctions pas encore écrites sont visibles mais inertes', (tester) async {
    await pumpHome(tester);

    expect(isEnabled(tester, 'Gestion des joueurs'), isFalse);
    expect(isEnabled(tester, 'Statistiques'), isFalse);
  });
}
