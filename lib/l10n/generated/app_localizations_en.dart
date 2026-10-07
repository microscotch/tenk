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
  String get validateButton => 'Confirm';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get helpTooltip => 'Game rules';

  @override
  String get aboutTooltip => 'About';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Close';

  @override
  String playersCountTitle(int count) {
    return 'Players ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Start game';

  @override
  String get newGameSectionLabel => 'New run...';

  @override
  String get resumeGamesButton => 'Resume games';

  @override
  String get managePlayersButton => 'Manage players';

  @override
  String get finishedGamesButton => 'Recently finished games';

  @override
  String get statisticsButton => 'Statistics';

  @override
  String playersScreenTitle(int count) {
    return 'Players ($count)';
  }

  @override
  String get addPlayerTooltip => 'Add a player';

  @override
  String get noPlayersMessage => 'No players saved yet.';

  @override
  String get newPlayerTitle => 'New player';

  @override
  String get editPlayerTitle => 'Edit player';

  @override
  String get playerNameLabel => 'Name';

  @override
  String get playerNicknameLabel => 'Nickname (optional)';

  @override
  String get playerNameRequiredError => 'A name is required.';

  @override
  String get playerNameTakenError =>
      'This name is already used by another player.';

  @override
  String get deletePlayerConfirmTitle => 'Delete this player?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'The profile of “$name” and its statistics will be permanently deleted. Games already played are kept.';
  }

  @override
  String get statsSectionTime => 'Playing time';

  @override
  String get statsSectionGames => 'Games';

  @override
  String get statsSectionFigures => 'Combinations';

  @override
  String get statsSectionRolls => 'Turns and rolls';

  @override
  String get statsTurns => 'Turns played';

  @override
  String get statsRolls => 'Rolls';

  @override
  String get statsRollsPerTurn => 'Rolls per turn';

  @override
  String get statsSectionMisc => 'Feats';

  @override
  String get statsTotalTime => 'Total';

  @override
  String get statsAverageTime => 'Average per game';

  @override
  String get statsShortestTime => 'Shortest';

  @override
  String get statsLongestTime => 'Longest';

  @override
  String get statsGamesPlayed => 'Played';

  @override
  String get statsGamesWon => 'Won';

  @override
  String get statsGamesLost => 'Lost';

  @override
  String get statsLoneAces => 'Single 1s kept';

  @override
  String get statsLoneFives => 'Single 5s kept';

  @override
  String get statsBrelans => 'Three of a kind';

  @override
  String get statsCarres => 'Four of a kind';

  @override
  String get statsQuintes => 'Five of a kind';

  @override
  String get statsSuites => 'Straights';

  @override
  String get statsSmallSuites => 'of which low';

  @override
  String get statsBigSuites => 'of which high';

  @override
  String get statsAceQuints => 'Five 1s';

  @override
  String get statsAceQuintsWon => 'of which winning';

  @override
  String get statsBestTurn => 'Best turn';

  @override
  String get statsHotDiceRun => 'Hot dice in a row';

  @override
  String get statsBusts => 'Busts';

  @override
  String get statsLongestBustStreak => 'longest streak';

  @override
  String get statsSelfBars => 'Self-crossed out';

  @override
  String get statsBarsInflicted => 'Crossed out others';

  @override
  String get scoreChartTitle => 'Score progression';

  @override
  String get gameStatsTitle => 'Game statistics';

  @override
  String get gameStatsGameSection => 'Game';

  @override
  String get gameStatsFiguresSection => 'Combinations this game';

  @override
  String get gameStatsDuration => 'Playing time';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turns',
      one: '$turns turn',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts busts',
      one: '$busts bust',
    );
    return '$_temp0 · best $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games games',
      one: '$games game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won won',
      one: '$won won',
    );
    return '$_temp0 · $_temp1 · best $best';
  }

  @override
  String get scoreChartEmpty =>
      'No turn finished yet: there is nothing to plot.';

  @override
  String get replayUnavailable =>
      'This game can\'t be replayed: its log is incomplete.';

  @override
  String get replayPlay => 'Play';

  @override
  String get replayPause => 'Pause';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Turn $turn';
  }

  @override
  String get scoreChartXAxis => 'Turns played';

  @override
  String get statsBreakdownRow => 'of which';

  @override
  String get statsRecordsTitle => 'Records';

  @override
  String get statsNoRecordYet => 'No records yet.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Choose players';

  @override
  String get addHumanTooltip => 'Add a player';

  @override
  String get addBotTooltip => 'Add a bot';

  @override
  String get createPlayerButton => 'New player';

  @override
  String get noPlayersToPickMessage =>
      'No players saved. Create one to get started.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Remove from the game';

  @override
  String get notEnoughPlayersMessage => 'At least two players are needed.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count games played',
      one: '$count game played',
      zero: 'No games played',
    );
    return '$_temp0';
  }

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
  String get gameRunParticipantsSeparator => ' vs ';

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
  String get resumeLastGameDialogTitle => 'Resume the game?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'A game “$alias” is in progress. Do you want to resume it?';
  }

  @override
  String get resumeGameButton => 'Resume';

  @override
  String get gameOverReplayButton => 'Watch the game again';

  @override
  String get scoreGridLabel => 'Score grid';

  @override
  String get finalRoundBanner => 'Final round: a player has reached 10000!';

  @override
  String get currentRollZoneLabel => 'Track';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Track ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Current hand';

  @override
  String get logHotDiceMessage => 'Hot dice!';

  @override
  String get logScoreCollisionMessage => 'Score crossed out:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return '$kept: $gain, $_temp0 => $total pts';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, hot dice => $total pts';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score pts banked => $total pts';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score pts taken over';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Busted! => $score strike';
  }

  @override
  String get logBustBarredPrefix => 'Busted! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'back to $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Taking over this hand would already exceed 10000: can\'t bank.';

  @override
  String get rollButton => 'Roll';

  @override
  String get showProbabilitiesSetting => 'Show probabilities';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Shows on the \"Roll\" button the chance of scoring at least one point';

  @override
  String get stopButton => 'Stop';

  @override
  String get bustedTitle => 'Busted!';

  @override
  String get bustExceedsTarget => 'This roll would go over 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Hot dice at 10000: you can\'t stop, and rerolling everything would go over.';

  @override
  String get bustContinueButton => 'Continue';

  @override
  String get inheritedHandDialogTitle => 'Take over?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dice',
      one: '$count die',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Take over the hand';

  @override
  String get newHandButton => 'New hand';

  @override
  String get failureBelowMinimum => 'Score too low to stop.';

  @override
  String get failureEndsIn50 => 'You can\'t stop on a score ending in 50.';

  @override
  String get failureMustContinueHotDice => 'You must reroll.';

  @override
  String get failureMustContinueFinalRound =>
      'Can\'t stop: the final round requires reaching exactly 10000.';

  @override
  String get failureNotRolledYet =>
      'You must roll the dice before you can stop.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Stopping now would make reaching exactly 10000 impossible.';

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
  String get settingsHandednessLabel => 'Button layout';

  @override
  String get settingsHandednessRight => 'Right-handed';

  @override
  String get settingsHandednessLeft => 'Left-handed';

  @override
  String get settingsControlsTitle => 'Controls';

  @override
  String get settingsShakeToRollLabel => 'Shake to roll the dice';

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
  String get reorderPlayersHint =>
      'Drag a player by their handle to change the order around the table.';

  @override
  String get reorderPlayerHandleLabel => 'Move this player';

  @override
  String get diceOffTitle => 'Who starts?';

  @override
  String get diceOffInstructions =>
      'Everyone rolls their die at the same time: the lowest starts. On a tie, the tied players roll again.';

  @override
  String diceOffTieBreak(String names) {
    return 'Tie: $names roll again.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName starts the game!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Turn order';

  @override
  String get diceOffReversedNote =>
      'Duel between neighbours won by the second: play goes the other way round.';

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
  String get rankFirstTooltip => 'In the lead';

  @override
  String get rankSecondTooltip => '2nd on score';

  @override
  String get rankThirdTooltip => '3rd on score';

  @override
  String get rulesScreenTitle => 'Game rules';

  @override
  String get rulesGoalTitle => 'Goal of the game';

  @override
  String get rulesGoalBody =>
      'Reach exactly 10,000 points. Going over doesn\'t count.';

  @override
  String get rulesTurnTitle => 'How a turn works';

  @override
  String get rulesTurnBody =>
      'You roll 5 dice, set aside at least one scoring die, then reroll the rest or stop and bank. If a roll scores nothing, it\'s a bust: you lose everything you accumulated this turn.';

  @override
  String get rulesScoringTitle => 'What scores points';

  @override
  String get rulesScoringBody =>
      '• A single ace (1): 100 points. A single 5: 50 points. Other single values (2, 3, 4, 6) score nothing.\n• Three of a kind: the die value × 100 (three 6s are worth 600), except three aces, worth 1000.\n• Four of a kind: 1000 more than the matching three of a kind (four 6s are worth 1600, four aces 2000).\n• Five of a kind: the die value × 1000. Five aces (the ace quint) score 10,000 outright: an immediate win.\n• A straight of 5 (ace-2-3-4-5 or 2-3-4-5-6) is worth 500 points.';

  @override
  String get rulesBustTitle => 'Bust and barred';

  @override
  String get rulesBustBody =>
      'A bust puts a dash on your score line. If it already had one, the line is barred and you fall back to your previous score. If you reach the same total as another player, they are barred.';

  @override
  String get rulesEntryTitle => 'To stop';

  @override
  String get rulesEntryBody =>
      '• You need at least 500 points to get into the game, then at least 200 per turn.\n• You can never stop on a turn total ending in 50 (250, 450…).\n• If all your dice score (\"hot dice\"), you must reroll all 5.';

  @override
  String get rulesExtensionTitle => 'The extension rule';

  @override
  String get rulesExtensionBody =>
      'Once a three or four of a kind is banked, any single die of the same value later in the turn is worth 100, including a 5. It ends on hot dice.';

  @override
  String get rulesInheritTitle => 'Inheriting the previous player\'s dice';

  @override
  String get rulesInheritBody =>
      'If you stop with unrolled dice, the next player may take those dice and your score as a base, or start with 5 fresh dice. After a bust, they always start with 5 fresh dice.';

  @override
  String get rulesVictoryTitle => 'Exactly 10,000 and the final round';

  @override
  String get rulesVictoryBody =>
      'As soon as a roll lets you land on exactly 10,000, the take is automatic and the turn ends. The other players then get one last turn to match that score: nobody may stop below 10,000 in it, you must match it or bust. If another player also hits 10,000, they bar the first and a new final round starts around them.\nSpecial case: a full hand landing exactly on 10,000 is a bust, since it forces a reroll. Only the ace quint wins.';

  @override
  String get onlinePlayButton => 'Play online';

  @override
  String get onlineResumeButton => 'Resume the online game';

  @override
  String get onlineTitle => 'Online game';

  @override
  String get onlineCreateButton => 'Create a room';

  @override
  String get onlineJoinButton => 'Join';

  @override
  String get onlineCodeLabel => 'Room code';

  @override
  String get onlineOrDivider => 'or';

  @override
  String get onlineShareHint =>
      'Give this code to the other players so they can join you.';

  @override
  String get onlineShareButton => 'Share the code';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Join my online game of Le 10000! Room code: $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Players ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Host';

  @override
  String get onlineDisconnectedBadge => 'Disconnected';

  @override
  String get onlineNeedTwoPlayers =>
      'At least 2 players are needed, all connected.';

  @override
  String get onlineWaitingForHost => 'Waiting for the host to start…';

  @override
  String get onlineLeaveButton => 'Leave';

  @override
  String get onlineLeaveConfirmTitle => 'Leave the online game?';

  @override
  String get onlineLeaveConfirmBody =>
      'In a game that has started, your seat stays empty and the game waits for you to come back.';

  @override
  String get onlineConnecting => 'Connecting to the server…';

  @override
  String get onlineReconnecting => 'Connection lost, reconnecting…';

  @override
  String get onlineSuspended =>
      'Game suspended: a player has been away for too long.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName is playing…';
  }

  @override
  String get onlineDiceOffContinue => 'Play';

  @override
  String get onlineErrorUnreachable => 'Server unreachable.';

  @override
  String get onlineErrorRoomNotFound => 'No room with this code.';

  @override
  String get onlineErrorRoomFull => 'This room is full.';

  @override
  String get onlineErrorGameStarted => 'This game has already started.';

  @override
  String get onlineErrorRateLimited =>
      'Too many attempts: try again in a moment.';

  @override
  String get onlineErrorBadToken => 'Your seat in this room no longer exists.';

  @override
  String get onlineErrorUnsupportedVersion => 'Update the app to play online.';

  @override
  String get onlineErrorGeneric => 'Something went wrong.';

  @override
  String get myProfileTitle => 'My profile';

  @override
  String get myProfileWelcomeTitle => 'Welcome!';

  @override
  String get myProfileWelcomeMessage =>
      'Create your profile: your name, a nickname if you like, and the hand you play with. Online, other players will see your nickname, or your name if you have none.';

  @override
  String get myProfileExistingPrompt =>
      'Already in the players list? Tap your name.';

  @override
  String get myProfileCreateButton => 'Create my profile';

  @override
  String get myProfileEditButton => 'Edit my profile';

  @override
  String get myProfileBadge => 'Me';

  @override
  String onlinePlayingAs(String name) {
    return 'You are playing as “$name”';
  }

  @override
  String get onlineNameInvalidError =>
      'Online, your nickname (or your name) must be at most 20 characters, with no invisible character.';

  @override
  String get settingsDiceSoundLabel => 'Dice sound';

  @override
  String get settingsDiceSoundRealistic => 'Realistic';

  @override
  String get settingsDiceSoundSynthetic => 'Synthetic';

  @override
  String get homeChipsHint => 'Long-press a chip to see its name.';

  @override
  String get emoteThoughtful => 'Thoughtful';

  @override
  String get emoteMocking => 'Dying of laughter';

  @override
  String get emoteDevastated => 'Devastated';

  @override
  String get emoteJoyful => 'Hug';

  @override
  String get emotePhraseCoincidence => 'What a coincidence...';

  @override
  String get emotePhraseStickyFive => 'Sticky five!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Full hand, empty hand!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Never take over a 1000!';

  @override
  String get emotePhraseNoWay => 'Just not possible!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Hi!';

  @override
  String get emotePhraseYes => 'Yes!';

  @override
  String get emotePhraseTooGreedy => 'Too greedy!';

  @override
  String get emotePhraseTooLucky => 'A bit too lucky...';

  @override
  String get emotePhraseDryTenThousand => 'Going for a straight 10000';

  @override
  String get emotePhraseLucky => 'Lucky devil!';

  @override
  String get emotePhraseGoodLuck => 'Good luck!';

  @override
  String get emotePhraseThanks => 'Thanks';

  @override
  String get emotePhraseSorryMustGo => 'Sorry, but I have to go';

  @override
  String get gameHistoryBar => 'History';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'A new version is available ($version, build $build).';
  }

  @override
  String get updateNowButton => 'Update';

  @override
  String get updateLaterButton => 'Later';
}
