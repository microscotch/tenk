import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/finished_games_screen.dart';
import 'package:le10000/ui/screens/new_game_screen.dart';
import 'package:le10000/ui/screens/online_entry_screen.dart';
import 'package:le10000/ui/screens/paused_games_screen.dart';
import 'package:le10000/ui/screens/players_screen.dart';
import 'package:le10000/ui/screens/rules_screen.dart';
import 'package:le10000/ui/screens/settings_screen.dart';
import 'package:le10000/ui/screens/statistics_screen.dart';
import 'package:le10000/ui/screens/setup_screen.dart';
import 'package:le10000/ui/widgets/app_title.dart';
import 'package:le10000/ui/widgets/casino_chip.dart';

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
  /// Le jeton du menu nommé [label] (son nom est son infobulle).
  Finder chip(String label) => find.byWidgetPredicate((w) => w is CasinoChip && w.label == label);

  bool isEnabled(WidgetTester tester, String label) => tester.widget<CasinoChip>(chip(label)).onPressed != null;

  const allLabels = [
    'Nouvelle partie',
    'Jouer en ligne',
    'Reprise de parties',
    'Gestion des joueurs',
    'Dernières parties terminées',
    'Statistiques',
    'Règles du jeu',
    'Paramètres',
    'À propos',
  ];

  testWidgets('l\'accueil est un rack de neuf jetons : une icône chacun, leur nom en infobulle', (tester) async {
    await pumpHome(tester);

    for (final label in allLabels) {
      expect(chip(label), findsOneWidget, reason: '$label doit être proposé');
      expect(find.text(label), findsNothing, reason: 'rien d\'écrit sur le jeton');
      expect(find.byTooltip(label), findsOneWidget, reason: 'son nom, à l\'appui long');
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: 'et pour un lecteur d\'écran');
    }
  });

  testWidgets('un appui long sur un jeton affiche son nom', (tester) async {
    await pumpHome(tester);

    await tester.longPress(chip('Statistiques'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Statistiques'), findsOneWidget);
    expect(find.byType(StatisticsScreen), findsNothing, reason: 'l\'appui long n\'ouvre rien');
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

    await tester.tap(chip('Reprise de parties'));
    await tester.pumpAndSettle();
    expect(find.byType(PausedGamesScreen), findsOneWidget);
    // Retour système : sur Android, la barre n'a pas de flèche (voir AppTopBar).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(chip('Dernières parties terminées'));
    await tester.pumpAndSettle();
    expect(find.byType(FinishedGamesScreen), findsOneWidget);
    // Retour système : sur Android, la barre n'a pas de flèche (voir AppTopBar).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.tap(chip('Nouvelle partie'));
    await tester.pumpAndSettle();
    expect(find.byType(NewGameScreen), findsOneWidget);
  });

  testWidgets('les parties en ligne s\'ouvrent depuis l\'accueil, à côté de « Nouvelle partie »', (tester) async {
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    final newGame = tester.getCenter(chip('Nouvelle partie'));
    final online = tester.getCenter(chip('Jouer en ligne'));
    expect(online.dy, newGame.dy, reason: 'sur la même rangée, la première');
    expect(online.dx, greaterThan(newGame.dx));

    await tester.tap(chip('Jouer en ligne'));
    await tester.pumpAndSettle();
    expect(find.byType(OnlineEntryScreen), findsOneWidget);
  });

  testWidgets('la gestion des joueurs s\'ouvre depuis l\'accueil', (tester) async {
    await pumpHome(tester);

    await tester.tap(chip('Gestion des joueurs'));
    await tester.pumpAndSettle();

    expect(find.byType(PlayersScreen), findsOneWidget);
  });

  testWidgets('tous les boutons sont actifs, reprise mise à part', (tester) async {
    await pumpHome(tester);

    for (final label in const [
      'Nouvelle partie',
      'Jouer en ligne',
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

  testWidgets('pas de barre du haut : règles, paramètres et à propos sont la dernière rangée du rack',
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

    // La dernière rangée du rack : règles, paramètres, à propos, chacun avec son icône.
    expect(find.text('TenK'), findsOneWidget, reason: 'le titre de l\'app, sans barre pour le porter');
    expect(tester.getTopLeft(find.text('TenK')).dy, lessThan(tester.getTopLeft(chip('Nouvelle partie')).dy));
    final lastRow = tester.getCenter(chip('Règles du jeu')).dy;
    expect(tester.getCenter(chip('Statistiques')).dy, lessThan(lastRow));
    for (final (label, icon) in [
      ('Règles du jeu', Icons.help_outline),
      ('Paramètres', Icons.settings),
      ('À propos', Icons.info_outline),
    ]) {
      expect(tester.getCenter(chip(label)).dy, lastRow, reason: label);
      expect(find.descendant(of: chip(label), matching: find.byIcon(icon)), findsOneWidget, reason: label);
    }

    await tester.ensureVisible(chip('Règles du jeu'));
    await tester.tap(chip('Règles du jeu'));
    await tester.pumpAndSettle();
    expect(find.byType(RulesScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(chip('Paramètres'));
    await tester.tap(chip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    await tester.ensureVisible(chip('À propos'));
    await tester.tap(chip('À propos'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget, reason: 'le dialogue « À propos »');
  });

  testWidgets('deux zones : le titre calé en haut, le rack centré dans le reste de l\'écran', (tester) async {
    // Un téléphone en portrait.
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    // La zone du titre, et non son texte, plus petit que l'icône du dé.
    final title = tester.getRect(find.byType(AppTitle));
    expect(title.top, lessThan(60), reason: 'le titre est en haut de l\'écran, pas au milieu');

    final first = tester.getRect(chip('Nouvelle partie'));
    final last = tester.getRect(chip('À propos'));
    final hint = tester.getRect(find.text('Appui long sur un jeton : son nom s\'affiche.'));
    // Le rack est centré entre le titre et la ligne d'aide : autant de place
    // au-dessus qu'en dessous.
    expect(first.top - title.bottom, closeTo(hint.top - last.bottom, 2));
    expect(first.top - title.bottom, greaterThan(60), reason: 'l\'écran est assez haut pour l\'aérer');
    expect(hint.bottom, lessThanOrEqualTo(915));
  });

  testWidgets('sur un téléphone étroit, les jetons rapetissent mais gardent trois colonnes', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpHome(tester);
    await dismissResumeOffer(tester);

    double row(String label) => tester.getCenter(chip(label)).dy;
    expect(row('Jouer en ligne'), row('Nouvelle partie'));
    expect(row('Reprise de parties'), row('Nouvelle partie'), reason: 'trois par rangée');
    expect(row('Gestion des joueurs'), greaterThan(row('Nouvelle partie')));
    expect(tester.getSize(chip('Nouvelle partie')).width, lessThan(96));
    expect(tester.takeException(), isNull, reason: 'aucun débordement');
  });
}
