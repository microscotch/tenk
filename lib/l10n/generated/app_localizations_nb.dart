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
  String get pausedGamesSectionLabel => 'Avbrutte runs';

  @override
  String get finishedRunsSectionLabel => 'Fullførte runs';

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
  String get leaveGameTooltip => 'Forlat spillet';

  @override
  String get scoreGridLabel => 'Poengtabell';

  @override
  String get finalRoundBanner => 'Siste runde: en spiller har nådd 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Poeng denne runden: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minimum kreves: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Beholdte terninger denne runden';

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
  String thisRollScoreLabel(int score) {
    return 'Poeng for dette kastet: $score';
  }

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
}
