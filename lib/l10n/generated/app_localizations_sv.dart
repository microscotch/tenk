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
  String get autoChipLabel => 'Auto';

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
  String get scoreGridLabel => 'Poängtabell';

  @override
  String get finalRoundBanner => 'Sista rundan: en spelare har nått 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Poäng denna runda: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minimum som krävs: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Sparade tärningar denna runda';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount tärningar',
      one: '$diceCount tärning',
    );
    return '$playerName ärver $_temp0 från föregående runda.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Aktuellt poäng: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return 'Fortsätt med $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Att ta över denna hand skulle redan överskrida 10000: kan inte stanna.';

  @override
  String get restartWithFreshDiceButton => 'Börja om med 5 nya tärningar';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return 'Ta över med $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Börja om med 5 nya tärningar';

  @override
  String get keepDiceButton => 'Behåll tärningarna';

  @override
  String get reRollFullHandButton => 'Kasta igen (heta tärningar)';

  @override
  String get stopButton => 'Stanna';

  @override
  String get rollDiceButton => 'Kasta tärningarna';

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
  String get continueButton => 'Fortsätt';

  @override
  String thisRollScoreLabel(int score) {
    return 'Poäng för detta kast: $score';
  }

  @override
  String get howManyFivesToKeep => 'Hur många femmor vill du behålla?';

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
  String get newGameButton => 'Nytt spel';

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
}
