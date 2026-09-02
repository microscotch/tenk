// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get splashPresents => 'präsentiert';

  @override
  String get ownerNameDialogTitle => 'Wie heißt du?';

  @override
  String get ownerNameFieldLabel => 'Name des Hauptspielers';

  @override
  String get laterButton => 'Später';

  @override
  String get validateButton => 'Bestätigen';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String playersCountTitle(int count) {
    return 'Spieler ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Spieler $number';
  }

  @override
  String get unnamedPlayerFallback => 'Spieler';

  @override
  String playerNameFieldLabel(int number) {
    return 'Name von Spieler $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'KI';

  @override
  String get addPlayerButton => 'Hinzufügen';

  @override
  String get removePlayerButton => 'Entfernen';

  @override
  String get botDifficultyTitle => 'Bot-Schwierigkeit';

  @override
  String get aiDifficultyCautious => 'Vorsichtig';

  @override
  String get aiDifficultyBalanced => 'Ausgewogen';

  @override
  String get aiDifficultyAggressive => 'Aggressiv';

  @override
  String get startGameButton => 'Spiel starten';

  @override
  String get newGameSectionLabel => 'Neuer Run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Unterbrochene Runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Beendete Runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Noch keine pausierten Spiele.';

  @override
  String get noFinishedRunsMessage => 'Noch keine beendeten Runs.';

  @override
  String get deleteGameConfirmTitle => 'Dieses Spiel löschen?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Das Spiel „$alias“ wird endgültig gelöscht.';
  }

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get leaveGameTooltip => 'Spiel verlassen';

  @override
  String get scoreGridLabel => 'Punktetabelle';

  @override
  String get finalRoundBanner =>
      'Letzte Runde: Ein Spieler hat 10000 erreicht!';

  @override
  String turnScoreLabel(int score) {
    return 'Punkte dieser Runde: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Mindestpunktzahl: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Diese Runde behaltene Würfel';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount Würfel',
      one: '$diceCount Würfel',
    );
    return '$playerName übernimmt $_temp0 von der vorigen Runde.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Aktuelle Punktzahl: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfeln',
      one: '$count Würfel',
    );
    return 'Weiter mit $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Diese Hand zu übernehmen würde bereits 10000 überschreiten: Einlösen nicht möglich.';

  @override
  String get restartWithFreshDiceButton => 'Neu starten mit 5 frischen Würfeln';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfeln',
      one: '$count Würfel',
    );
    return 'Übernehmen mit $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel =>
      'Neu starten mit 5 frischen Würfeln';

  @override
  String get keepDiceButton => 'Würfel behalten';

  @override
  String get reRollFullHandButton => 'Erneut würfeln (heiße Würfel)';

  @override
  String get stopButton => 'Aufhören';

  @override
  String get rollDiceButton => 'Würfeln';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfel',
      one: '$count Würfel',
    );
    return '$_temp0 zu würfeln';
  }

  @override
  String get bustedTitle => 'Verloren!';

  @override
  String get bustExceedsTarget => 'Dieser Wurf würde 10000 überschreiten.';

  @override
  String get continueButton => 'Weiter';

  @override
  String thisRollScoreLabel(int score) {
    return 'Punkte dieses Wurfs: $score';
  }

  @override
  String get howManyFivesToKeep => 'Wie viele 5en behalten?';

  @override
  String get fullHandMustReroll => 'Heiße Würfel: Du musst erneut würfeln!';

  @override
  String get failureBelowMinimum => 'Punktzahl zu niedrig, um aufzuhören.';

  @override
  String get failureEndsIn50 =>
      'Du darfst nicht bei einer Punktzahl aufhören, die auf 50 endet.';

  @override
  String get failureMustContinueHotDice => 'Du musst erneut würfeln.';

  @override
  String get failureNotRolledYet =>
      'Du musst würfeln, bevor du aufhören kannst.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Jetzt aufzuhören würde es unmöglich machen, genau 10000 zu erreichen.';

  @override
  String get settingsMainPlayerTitle => 'Hauptspieler';

  @override
  String get settingsYourNameLabel => 'Dein Name (Gerätebesitzer)';

  @override
  String get settingsDelaysTitle => 'Verzögerungen';

  @override
  String get settingsDelaysDescription =>
      'Verzögerung, bevor eine automatische Aktion von selbst ausgelöst wird. 0 zum Deaktivieren.';

  @override
  String get settingsAiDelayLabel => 'KI-Nachrichten (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatische Aktionen des menschlichen Spielers (ms)';

  @override
  String get settingsDiceTitle => 'Würfel';

  @override
  String get settingsDiceUniform => 'Einheitlich';

  @override
  String get settingsDiceVaried => 'Bunt gemischt';

  @override
  String get settingsSoundsTitle => 'Sound';

  @override
  String get settingsMusicLabel => 'Hintergrundmusik';

  @override
  String get settingsSoundEffectsLabel => 'Soundeffekte';

  @override
  String get settingsPausedGamesTitle => 'Pausierte Spiele';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Vor dem Löschen eines Spiels bestätigen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSystemOption => 'Telefonsprache';

  @override
  String get diceOffTitle => 'Wer beginnt?';

  @override
  String get diceOffInstructions =>
      'Jeder würfelt einmal: Die niedrigste Punktzahl beginnt das Spiel.';

  @override
  String diceOffTieBreak(String names) {
    return 'Unentschieden: $names würfeln erneut.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName würfelt';
  }

  @override
  String get diceOffRollButton => 'Würfeln';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName beginnt das Spiel!';
  }

  @override
  String get gameOverTitle => 'Spielende';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName gewinnt!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Neues Spiel';

  @override
  String get passDeviceInstruction => 'Gib das Gerät weiter an';

  @override
  String get readyButton => 'Bereit';

  @override
  String get notEnteredLabel => '(noch nicht eingestiegen)';

  @override
  String get opportunityTooltip =>
      'Nur 200 Punkte davon entfernt, den Spieler direkt darüber zu streichen!';

  @override
  String get dangerTooltip =>
      'Gefahr: Der Spieler direkt darunter ist nur 200 Punkte entfernt und könnte dich streichen';

  @override
  String get tiretTooltip =>
      'Strich: Ein zweiter Fehlwurf streicht die Punktzahl';

  @override
  String get previousScoreHadTiretTooltip =>
      'Die vorige Punktzahl trug einen Strich';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfeln',
      one: '$count Würfel',
    );
    return 'Trefferwahrscheinlichkeit mit $_temp0';
  }
}
