// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get splashPresents => 'presents';

  @override
  String get ownerNameDialogTitle => 'Your name?';

  @override
  String get ownerNameFieldLabel => 'Main player\'s name';

  @override
  String get laterButton => 'Later';

  @override
  String get validateButton => 'Confirm';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String playersCountTitle(int count) {
    return 'Players ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Player $number';
  }

  @override
  String get unnamedPlayerFallback => 'Player';

  @override
  String playerNameFieldLabel(int number) {
    return 'Player $number name';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'AI';

  @override
  String get addPlayerButton => 'Add';

  @override
  String get removePlayerButton => 'Remove';

  @override
  String get botDifficultyTitle => 'Bot difficulty';

  @override
  String get aiDifficultyCautious => 'Cautious';

  @override
  String get aiDifficultyBalanced => 'Balanced';

  @override
  String get aiDifficultyAggressive => 'Aggressive';

  @override
  String get startGameButton => 'Start game';

  @override
  String get newGameSectionLabel => 'New run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Interrupted runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Finished runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'No paused games yet.';

  @override
  String get noFinishedRunsMessage => 'No finished runs yet.';

  @override
  String get deleteGameConfirmTitle => 'Delete this game?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'The game “$alias” will be permanently deleted.';
  }

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get leaveGameTooltip => 'Leave game';

  @override
  String get scoreGridLabel => 'Score grid';

  @override
  String get finalRoundBanner => 'Final round: a player has reached 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Turn score: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minimum required: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Dice kept this turn';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount dice',
      one: '$diceCount die',
    );
    return '$playerName inherits $_temp0 from the previous turn.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Current score: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return 'Continue with $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Taking over this hand would already exceed 10000: can\'t bank.';

  @override
  String get restartWithFreshDiceButton => 'Start over with 5 fresh dice';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return 'Take over with $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Start over with 5 fresh dice';

  @override
  String get keepDiceButton => 'Keep the dice';

  @override
  String get reRollFullHandButton => 'Reroll (hot dice)';

  @override
  String get stopButton => 'Stop';

  @override
  String get rollDiceButton => 'Roll the dice';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return '$_temp0 to roll';
  }

  @override
  String get bustedTitle => 'Busted!';

  @override
  String get bustExceedsTarget => 'This roll would go over 10000.';

  @override
  String get continueButton => 'Continue';

  @override
  String thisRollScoreLabel(int score) {
    return 'This roll\'s score: $score';
  }

  @override
  String get howManyFivesToKeep => 'How many 5s to keep?';

  @override
  String get fullHandMustReroll => 'Hot dice: you must reroll!';

  @override
  String get failureBelowMinimum => 'Score too low to stop.';

  @override
  String get failureEndsIn50 => 'You can\'t stop on a score ending in 50.';

  @override
  String get failureMustContinueHotDice => 'You must reroll.';

  @override
  String get failureNotRolledYet =>
      'You must roll the dice before you can stop.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Stopping now would make reaching exactly 10000 impossible.';

  @override
  String get settingsMainPlayerTitle => 'Main player';

  @override
  String get settingsYourNameLabel => 'Your name (device owner)';

  @override
  String get settingsDelaysTitle => 'Delays';

  @override
  String get settingsDelaysDescription =>
      'Delay before an automatic action triggers on its own. 0 to disable.';

  @override
  String get settingsAiDelayLabel => 'AI messages (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Human player automatic actions (ms)';

  @override
  String get settingsDiceTitle => 'Dice';

  @override
  String get settingsDiceUniform => 'Uniform';

  @override
  String get settingsDiceVaried => 'Mixed';

  @override
  String get settingsSoundsTitle => 'Sound';

  @override
  String get settingsMusicLabel => 'Background music';

  @override
  String get settingsSoundEffectsLabel => 'Sound effects';

  @override
  String get settingsPausedGamesTitle => 'Paused games';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirm before deleting a game';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSystemOption => 'Phone language';

  @override
  String get diceOffTitle => 'Who starts?';

  @override
  String get diceOffInstructions =>
      'Everyone rolls a die: the lowest score starts the game.';

  @override
  String diceOffTieBreak(String names) {
    return 'Tie: $names roll again.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName rolls the die';
  }

  @override
  String get diceOffRollButton => 'Roll the die';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName starts the game!';
  }

  @override
  String get gameOverTitle => 'Game over';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName wins!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'New game';

  @override
  String get passDeviceInstruction => 'Pass the device to';

  @override
  String get readyButton => 'Ready';

  @override
  String get notEnteredLabel => '(not entered)';

  @override
  String get opportunityTooltip =>
      '200 points away from crossing out the player just above!';

  @override
  String get dangerTooltip =>
      'Danger: the player just below is only 200 points away, risking crossing you out';

  @override
  String get tiretTooltip => 'Strike: a second bust will cross out the score';

  @override
  String get previousScoreHadTiretTooltip => 'The previous score had a strike';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return 'Probability of scoring with $_temp0';
  }
}
