// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get splashPresents => 'presenterar';

  @override
  String get ownerNameDialogTitle => 'Vad heter du?';

  @override
  String get ownerNameFieldLabel => 'Huvudspelarens namn';

  @override
  String get laterButton => 'Senare';

  @override
  String get validateButton => 'Bekräfta';

  @override
  String get settingsTooltip => 'Inställningar';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String get aboutTooltip => 'À propos';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Fermer';

  @override
  String get okButton => 'OK';

  @override
  String playersCountTitle(int count) {
    return 'Spelare ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Spelare $number';
  }

  @override
  String get unnamedPlayerFallback => 'Spelare';

  @override
  String playerNameFieldLabel(int number) {
    return 'Namn på spelare $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'AI';

  @override
  String get addPlayerButton => 'Lägg till';

  @override
  String get removePlayerButton => 'Ta bort';

  @override
  String get botDifficultyTitle => 'Botsvårighetsgrad';

  @override
  String get aiDifficultyCautious => 'Försiktig';

  @override
  String get aiDifficultyBalanced => 'Balanserad';

  @override
  String get aiDifficultyAggressive => 'Aggressiv';

  @override
  String get startGameButton => 'Starta spelet';

  @override
  String get newGameSectionLabel => 'Ny run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Avbrutna runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Avslutade runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Inga pausade spel än.';

  @override
  String get noFinishedRunsMessage => 'Inga avslutade runs än.';

  @override
  String get deleteGameConfirmTitle => 'Radera det här spelet?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Spelet ”$alias” kommer att raderas permanent.';
  }

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get deleteButton => 'Radera';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Lämna spelet';

  @override
  String get scoreGridLabel => 'Poängtabell';

  @override
  String get finalRoundBanner => 'Sista rundan: en spelare har nått 10000!';

  @override
  String get currentRollZoneLabel => 'Piste';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Piste ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Main courante';

  @override
  String get awaitingRollPlaceholder => 'En attente du prochain lancer';

  @override
  String get logHotDiceMessage => 'Main pleine !';

  @override
  String get logScoreCollisionMessage => 'Score barré :';

  @override
  String logBankedMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return '$score $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Att ta över denna hand skulle redan överskrida 10000: kan inte stanna.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel => 'Börja om med 5 nya tärningar';

  @override
  String get keepDiceButton => 'Behåll tärningarna';

  @override
  String get stopButton => 'Stanna';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return '$_temp0 att kasta';
  }

  @override
  String get bustedTitle => 'Bom!';

  @override
  String get bustExceedsTarget => 'Detta kast skulle överskrida 10000.';

  @override
  String get fullHandMustReroll => 'Heta tärningar: du måste kasta igen!';

  @override
  String get failureBelowMinimum => 'För lågt poäng för att stanna.';

  @override
  String get failureEndsIn50 =>
      'Du kan inte stanna på ett poäng som slutar på 50.';

  @override
  String get failureMustContinueHotDice => 'Du måste kasta igen.';

  @override
  String get failureNotRolledYet =>
      'Du måste kasta tärningarna innan du kan stanna.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Att stanna nu skulle göra det omöjligt att nå exakt 10000.';

  @override
  String get settingsMainPlayerTitle => 'Huvudspelare';

  @override
  String get settingsYourNameLabel => 'Ditt namn (enhetens ägare)';

  @override
  String get settingsDelaysTitle => 'Fördröjningar';

  @override
  String get settingsDelaysDescription =>
      'Fördröjning innan en automatisk åtgärd utlöses av sig själv. 0 för att inaktivera.';

  @override
  String get settingsAiDelayLabel => 'AI-meddelanden (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatiska åtgärder för den mänskliga spelaren (ms)';

  @override
  String get settingsDiceTitle => 'Tärningar';

  @override
  String get settingsDiceUniform => 'Enfärgad';

  @override
  String get settingsDiceVaried => 'Blandad';

  @override
  String get settingsSoundsTitle => 'Ljud';

  @override
  String get settingsMusicLabel => 'Bakgrundsmusik';

  @override
  String get settingsSoundEffectsLabel => 'Ljudeffekter';

  @override
  String get settingsPausedGamesTitle => 'Pausade spel';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Bekräfta innan ett spel raderas';

  @override
  String get settingsLanguageTitle => 'Språk';

  @override
  String get settingsLanguageSystemOption => 'Telefonens språk';

  @override
  String get diceOffTitle => 'Vem börjar?';

  @override
  String get diceOffInstructions =>
      'Alla kastar en tärning: lägsta poängen börjar spelet.';

  @override
  String diceOffTieBreak(String names) {
    return 'Oavgjort: $names kastar igen.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName kastar tärningen';
  }

  @override
  String get diceOffRollButton => 'Kasta tärningen';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName börjar spelet!';
  }

  @override
  String get gameOverTitle => 'Spelet är slut';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vinner!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Lämna över enheten till';

  @override
  String get readyButton => 'Klar';

  @override
  String get notEnteredLabel => '(inte inne än)';

  @override
  String get opportunityTooltip =>
      '200 poäng från att stryka spelaren precis ovanför!';

  @override
  String get dangerTooltip =>
      'Fara: spelaren precis under är bara 200 poäng bort, risk att du blir struken';

  @override
  String get tiretTooltip => 'Streck: ett andra bom kommer att stryka poängen';

  @override
  String get previousScoreHadTiretTooltip => 'Föregående poäng hade ett streck';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return 'Sannolikhet att poängsätta med $_temp0';
  }

  @override
  String get rulesScreenTitle => 'Règles du jeu';

  @override
  String get rulesGoalTitle => 'But du jeu';

  @override
  String get rulesGoalBody =>
      'Le premier joueur à atteindre exactement 10 000 points gagne la partie. Il faut viser ce chiffre pile : le dépasser ne compte pas.';

  @override
  String get rulesTurnTitle => 'Comment se joue un tour';

  @override
  String get rulesTurnBody =>
      'À votre tour, vous lancez 5 dés. Certaines valeurs rapportent des points (voir ci-dessous), d\'autres ne servent à rien. Vous mettez de côté au moins un dé qui rapporte, puis vous choisissez : relancer les dés restants pour tenter d\'engranger plus de points, ou vous arrêter et encaisser ce que vous avez accumulé ce tour. Si un lancer ne rapporte aucun point, c\'est un craque (voir plus bas) et vous perdez tout ce que vous aviez accumulé ce tour.';

  @override
  String get rulesScoringTitle => 'Ce qui rapporte des points';

  @override
  String get rulesScoringBody =>
      '• Un 1 isolé : 100 points. Un 5 isolé : 50 points. Les autres valeurs isolées (2, 3, 4, 6) ne rapportent rien.\n• Trois dés identiques : 1000 points pour trois 1, sinon la valeur du dé × 100 (trois 4 valent 400, trois 6 valent 600).\n• Un quatrième dé de la même valeur ajoute 1000 points de plus.\n• Les 5 dés identiques valent la valeur du dé × 1000, sauf cinq 1 qui rapportent directement 10 000 points : la victoire immédiate.\n• Une suite de 5 dés qui se suivent (1-2-3-4-5 ou 2-3-4-5-6) vaut 500 points.';

  @override
  String get rulesHotDiceTitle => 'Dés chauds : une seconde chance forcée';

  @override
  String get rulesHotDiceBody =>
      'Si tous les dés que vous venez de lancer rapportent des points, vous devez relancer les 5 dés en main : impossible de s\'arrêter à ce moment précis. C\'est ce qu\'on appelle des « dés chauds ».';

  @override
  String get rulesBustTitle => 'Le craque';

  @override
  String get rulesBustBody =>
      'Si un lancer ne rapporte strictement aucun point, votre tour s\'arrête immédiatement et vous perdez tous les points accumulés ce tour (ce que vous aviez déjà encaissé lors des tours précédents reste acquis). Un craque marque aussi votre ligne de score actuelle d\'un tiret ; si elle en portait déjà un, elle est barrée et votre score retombe à sa valeur précédente.';

  @override
  String get rulesEntryTitle => 'Entrer dans la partie';

  @override
  String get rulesEntryBody =>
      'Pour commencer à marquer des points, votre tout premier tour réussi doit rapporter au moins 500 points. Une fois entré dans la partie, chaque tour suivant doit rapporter au moins 200 points pour pouvoir s\'arrêter.';

  @override
  String get rulesNoFiftyTitle => 'Jamais de score finissant par 50';

  @override
  String get rulesNoFiftyBody =>
      'Vous ne pouvez jamais choisir de vous arrêter volontairement sur un total de tour qui finit par 50 (comme 250 ou 450) : il faut relancer les dés jusqu\'à obtenir un total valide.';

  @override
  String get rulesExtensionTitle => 'La règle d\'extension';

  @override
  String get rulesExtensionBody =>
      'Une fois que vous avez encaissé un brelan ou un carré d\'une valeur donnée (par exemple trois 4), tout dé isolé de cette même valeur obtenu plus tard dans le même tour rapporte 100 points au lieu de sa valeur habituelle — y compris un 5 isolé, qui vaut alors 100 au lieu de 50. Cet avantage disparaît dès que vous obtenez des dés chauds.';

  @override
  String get rulesInheritTitle => 'Hériter des dés du joueur précédent';

  @override
  String get rulesInheritBody =>
      'Quand un joueur s\'arrête volontairement en ayant encore des dés non lancés, le joueur suivant peut choisir de reprendre ces dés restants ainsi que le score déjà accumulé comme base de départ, ou de repartir à zéro avec 5 dés neufs. En cas de craque, en revanche, le joueur suivant repart toujours avec 5 dés neufs, sans rien hériter.';

  @override
  String get rulesBarredTitle => 'Tiret et barré';

  @override
  String get rulesBarredBody =>
      'Un craque place un tiret d\'avertissement sur votre ligne de score actuelle si elle n\'en a pas déjà un. Si elle en a déjà un, la ligne est barrée et votre score retombe à sa valeur précédente. Si votre score atteint exactement le même total qu\'un autre joueur, ce dernier est barré de la même façon, qu\'il ait déjà un tiret ou non.';

  @override
  String get rulesVictoryTitle => 'Comment gagner';

  @override
  String get rulesVictoryBody =>
      'Le premier joueur à atteindre exactement 10 000 points déclenche un tour final : chaque autre joueur a une dernière chance de l\'égaler ou de le dépasser à son tour. Si un autre joueur atteint lui aussi exactement 10 000 pendant ce tour final, il prend la couronne à sa place et un nouveau tour final recommence autour de lui.';
}
