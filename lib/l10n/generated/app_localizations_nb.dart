// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get splashPresents => 'presenterer';

  @override
  String get ownerNameDialogTitle => 'Hva heter du?';

  @override
  String get ownerNameFieldLabel => 'Navn på hovedspilleren';

  @override
  String get laterButton => 'Senere';

  @override
  String get validateButton => 'Bekreft';

  @override
  String get settingsTooltip => 'Innstillinger';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String playersCountTitle(int count) {
    return 'Spillere ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Spiller $number';
  }

  @override
  String get unnamedPlayerFallback => 'Spiller';

  @override
  String playerNameFieldLabel(int number) {
    return 'Navn på spiller $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'KI';

  @override
  String get addPlayerButton => 'Legg til';

  @override
  String get removePlayerButton => 'Fjern';

  @override
  String get botDifficultyTitle => 'Botvanskelighet';

  @override
  String get aiDifficultyCautious => 'Forsiktig';

  @override
  String get aiDifficultyBalanced => 'Balansert';

  @override
  String get aiDifficultyAggressive => 'Aggressiv';

  @override
  String get startGameButton => 'Start spillet';

  @override
  String get newGameSectionLabel => 'Ny run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Avbrutte runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Fullførte runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Ingen pausede spill ennå.';

  @override
  String get noFinishedRunsMessage => 'Ingen fullførte runs ennå.';

  @override
  String get deleteGameConfirmTitle => 'Slette dette spillet?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Spillet «$alias» blir slettet for godt.';
  }

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get deleteButton => 'Slett';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Forlat spillet';

  @override
  String get scoreGridLabel => 'Poengtabell';

  @override
  String get finalRoundBanner => 'Siste runde: en spiller har nådd 10000!';

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
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount terninger',
      one: '$diceCount terning',
    );
    return '$playerName arver $_temp0 fra forrige runde.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Nåværende poengsum: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return 'Fortsett med $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Å overta denne hånden ville allerede overskride 10000: kan ikke stoppe.';

  @override
  String get restartWithFreshDiceButton => 'Start på nytt med 5 nye terninger';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return 'Overta med $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Start på nytt med 5 nye terninger';

  @override
  String get keepDiceButton => 'Behold terningene';

  @override
  String get reRollFullHandButton => 'Kast på nytt (varme terninger)';

  @override
  String get stopButton => 'Stopp';

  @override
  String get rollDiceButton => 'Kast terningene';

  @override
  String rollDiceButtonWithCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return 'Lancer $_temp0';
  }

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return '$_temp0 å kaste';
  }

  @override
  String get bustedTitle => 'Bom!';

  @override
  String get bustExceedsTarget => 'Dette kastet ville overskride 10000.';

  @override
  String get continueButton => 'Fortsett';

  @override
  String get howManyFivesToKeep => 'Hvor mange femmere vil du beholde?';

  @override
  String get fullHandMustReroll => 'Varme terninger: du må kaste på nytt!';

  @override
  String get failureBelowMinimum => 'For lav poengsum til å stoppe.';

  @override
  String get failureEndsIn50 =>
      'Du kan ikke stoppe på en poengsum som ender på 50.';

  @override
  String get failureMustContinueHotDice => 'Du må kaste på nytt.';

  @override
  String get failureNotRolledYet => 'Du må kaste terningene før du kan stoppe.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Å stoppe nå ville gjort det umulig å nå nøyaktig 10000.';

  @override
  String get settingsMainPlayerTitle => 'Hovedspiller';

  @override
  String get settingsYourNameLabel => 'Ditt navn (eier av enheten)';

  @override
  String get settingsDelaysTitle => 'Forsinkelser';

  @override
  String get settingsDelaysDescription =>
      'Forsinkelse før en automatisk handling utløses av seg selv. 0 for å deaktivere.';

  @override
  String get settingsAiDelayLabel => 'KI-meldinger (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatiske handlinger for den menneskelige spilleren (ms)';

  @override
  String get settingsDiceTitle => 'Terninger';

  @override
  String get settingsDiceUniform => 'Ensfarget';

  @override
  String get settingsDiceVaried => 'Blandet';

  @override
  String get settingsSoundsTitle => 'Lyd';

  @override
  String get settingsMusicLabel => 'Bakgrunnsmusikk';

  @override
  String get settingsSoundEffectsLabel => 'Lydeffekter';

  @override
  String get settingsPausedGamesTitle => 'Pausede spill';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Bekreft før du sletter et spill';

  @override
  String get settingsLanguageTitle => 'Språk';

  @override
  String get settingsLanguageSystemOption => 'Telefonens språk';

  @override
  String get diceOffTitle => 'Hvem begynner?';

  @override
  String get diceOffInstructions =>
      'Alle kaster en terning: laveste poengsum begynner spillet.';

  @override
  String diceOffTieBreak(String names) {
    return 'Uavgjort: $names kaster på nytt.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName kaster terningen';
  }

  @override
  String get diceOffRollButton => 'Kast terningen';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName begynner spillet!';
  }

  @override
  String get gameOverTitle => 'Spillet er over';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vinner!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Nytt spill';

  @override
  String get passDeviceInstruction => 'Gi enheten videre til';

  @override
  String get readyButton => 'Klar';

  @override
  String get notEnteredLabel => '(ikke inne ennå)';

  @override
  String get opportunityTooltip =>
      '200 poeng unna å stryke spilleren rett over!';

  @override
  String get dangerTooltip =>
      'Fare: spilleren rett under er bare 200 poeng unna, risiko for å stryke deg';

  @override
  String get tiretTooltip => 'Strek: en ny bom vil stryke poengsummen';

  @override
  String get previousScoreHadTiretTooltip => 'Forrige poengsum hadde en strek';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return 'Sannsynlighet for å score med $_temp0';
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
