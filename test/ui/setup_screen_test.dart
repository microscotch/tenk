import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/finished_games_screen.dart';
import 'package:le10000/ui/screens/new_game_screen.dart';
import 'package:le10000/ui/screens/paused_games_screen.dart';
import 'package:le10000/ui/screens/players_screen.dart';
import 'package:le10000/ui/screens/rules_screen.dart';
import 'package:le10000/ui/screens/settings_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';
import 'package:le10000/ui/widgets/app_title.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

/// L'écran d'accueil, réduit à une colonne de boutons : les deux listes qui s'y
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
        playerStoreProvider.overrideWithValue(FakePlayerStore()),
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

  testWidgets('l\'accueil affiche ses huit boutons et plus aucune liste', (tester) async {
    await pumpHome(tester);

    for (final label in const [
      'Nouvelle partie',
      'Reprise de parties',
      'Gestion des joueurs',
      'Dernières parties terminées',
      'Statistiques',
      'Règles du jeu',
      'Paramètres',
      'À propos',
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
    // Retour système : sur Android, la barre n'a pas de flèche (voir AppTopBar).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dernières parties terminées'));
    await tester.pumpAndSettle();
    expect(find.byType(FinishedGamesScreen), findsOneWidget);
    // Retour système : sur Android, la barre n'a pas de flèche (voir AppTopBar).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nouvelle partie'));
    await tester.pumpAndSettle();
    expect(find.byType(NewGameScreen), findsOneWidget);
  });

  testWidgets('la gestion des joueurs s\'ouvre depuis l\'accueil', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Gestion des joueurs'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayersScreen), findsOneWidget);
  });

  testWidgets('tous les boutons sont actifs, reprise mise à part', (tester) async {
    await pumpHome(tester);

    for (final label in const [
      'Nouvelle partie',
      'Gestion des joueurs',
      'Dernières parties terminées',
      'Statistiques',
      'Règles du jeu',
      'Paramètres',
      'À propos',
    ]) {
      expect(isEnabled(tester, label), isTrue, reason: '$label doit être actif');
    }
  });

  testWidgets('pas de barre du haut : règles, paramètres et à propos sont des boutons, après Statistiques',
      (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'TenK',
      packageName: 'net.microscotch.games.tenk',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    expect(find.byType(AppBar), findsNothing);

    // Dans l'ordre demandé, chacun sous le précédent, préfixé de son icône.
    double top(String label) => tester.getTopLeft(find.text(label)).dy;
    expect(find.text('TenK'), findsOneWidget, reason: 'le titre de l\'app, sans barre pour le porter');
    expect(top('TenK'), lessThan(top('Nouvelle partie')), reason: 'en tête de la liste');
    expect(top('Statistiques'), lessThan(top('Règles du jeu')));
    expect(top('Règles du jeu'), lessThan(top('Paramètres')));
    expect(top('Paramètres'), lessThan(top('À propos')));
    for (final (label, icon) in [
      ('Règles du jeu', Icons.help_outline),
      ('Paramètres', Icons.settings),
      ('À propos', Icons.info_outline),
    ]) {
      final button = find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton));
      expect(find.descendant(of: button, matching: find.byIcon(icon)), findsOneWidget, reason: label);
    }

    await tester.ensureVisible(find.text('Règles du jeu'));
    await tester.tap(find.text('Règles du jeu'));
    await tester.pumpAndSettle();
    expect(find.byType(RulesScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Paramètres'));
    await tester.tap(find.text('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('À propos'));
    await tester.tap(find.text('À propos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'le dialogue « À propos »');
  });

  testWidgets('deux zones : le titre calé en haut, les boutons centrés dans le reste de l\'écran', (tester) async {
    // Un téléphone en portrait.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    // La zone du titre, et non son texte, plus petit que l'icône du dé.
    final title = tester.getRect(find.byType(AppTitle));
    expect(title.top, lessThan(60), reason: 'le titre est en haut de l\'écran, pas au milieu');

    Rect button(String label) => tester.getRect(find
        .ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton))
        .first);
    final first = button('Nouvelle partie');
    final last = button('À propos');
    // La zone des boutons va du bas du titre au bas de l'écran : centrés, ils
    // laissent autant de place au-dessus qu'en dessous.
    expect(first.top - title.bottom, closeTo(915 - last.bottom, 2));
    expect(first.top - title.bottom, greaterThan(100), reason: 'l\'écran est assez haut pour les aérer');
  });
}
