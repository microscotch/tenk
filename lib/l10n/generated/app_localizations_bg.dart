// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get splashPresents => 'представя';

  @override
  String get ownerNameDialogTitle => 'Как се казваш?';

  @override
  String get ownerNameFieldLabel => 'Име на основния играч';

  @override
  String get laterButton => 'По-късно';

  @override
  String get validateButton => 'Потвърди';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String playersCountTitle(int count) {
    return 'Играчи ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Играч $number';
  }

  @override
  String get unnamedPlayerFallback => 'Играч';

  @override
  String playerNameFieldLabel(int number) {
    return 'Име на играч $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'ИИ';

  @override
  String get addPlayerButton => 'Добави';

  @override
  String get removePlayerButton => 'Премахни';

  @override
  String get botDifficultyTitle => 'Трудност на ботовете';

  @override
  String get aiDifficultyCautious => 'Предпазлив';

  @override
  String get aiDifficultyBalanced => 'Балансиран';

  @override
  String get aiDifficultyAggressive => 'Агресивен';

  @override
  String get startGameButton => 'Започни играта';

  @override
  String get newGameSectionLabel => 'Нов run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Прекъснати runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Завършени runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Все още няма игри на пауза.';

  @override
  String get noFinishedRunsMessage => 'Все още няма завършени runs.';

  @override
  String get deleteGameConfirmTitle => 'Изтриване на тази игра?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Играта „$alias“ ще бъде окончателно изтрита.';
  }

  @override
  String get cancelButton => 'Отказ';

  @override
  String get deleteButton => 'Изтрий';

  @override
  String get leaveGameTooltip => 'Напусни играта';

  @override
  String get scoreGridLabel => 'Таблица с резултати';

  @override
  String get finalRoundBanner => 'Последен рунд: играч достигна 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Точки от хода: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Изискван минимум: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Запазени зарове този ход';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount зара',
      one: '$diceCount зар',
    );
    return '$playerName наследява $_temp0 от предишния ход.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Текущ резултат: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return 'Продължи с $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Поемането на тази ръка вече би надвишило 10000: не може да запишеш резултата.';

  @override
  String get restartWithFreshDiceButton => 'Започни отначало с 5 нови зара';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return 'Поеми с $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Започни отначало с 5 нови зара';

  @override
  String get keepDiceButton => 'Запази заровете';

  @override
  String get reRollFullHandButton => 'Хвърли отново (горещи зарове)';

  @override
  String get stopButton => 'Спри се';

  @override
  String get rollDiceButton => 'Хвърли заровете';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return '$_temp0 за хвърляне';
  }

  @override
  String get bustedTitle => 'Изгоря!';

  @override
  String get bustExceedsTarget => 'Това хвърляне би надвишило 10000.';

  @override
  String get continueButton => 'Продължи';

  @override
  String thisRollScoreLabel(int score) {
    return 'Точки от това хвърляне: $score';
  }

  @override
  String get howManyFivesToKeep => 'Колко петици да запазиш?';

  @override
  String get fullHandMustReroll => 'Горещи зарове: трябва да хвърлиш отново!';

  @override
  String get failureBelowMinimum => 'Недостатъчен резултат, за да спреш.';

  @override
  String get failureEndsIn50 =>
      'Не можеш да спреш на резултат, завършващ на 50.';

  @override
  String get failureMustContinueHotDice => 'Трябва да хвърлиш отново.';

  @override
  String get failureNotRolledYet =>
      'Трябва да хвърлиш заровете, преди да можеш да спреш.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Ако спреш сега, ще стане невъзможно да достигнеш точно 10000.';

  @override
  String get settingsMainPlayerTitle => 'Основен играч';

  @override
  String get settingsYourNameLabel => 'Твоето име (собственик на устройството)';

  @override
  String get settingsDelaysTitle => 'Забавяния';

  @override
  String get settingsDelaysDescription =>
      'Забавяне, преди автоматично действие да се задейства само. 0 за изключване.';

  @override
  String get settingsAiDelayLabel => 'Съобщения на ИИ (мс)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Автоматични действия на човешкия играч (мс)';

  @override
  String get settingsDiceTitle => 'Зарове';

  @override
  String get settingsDiceUniform => 'Еднакви';

  @override
  String get settingsDiceVaried => 'Разноцветни';

  @override
  String get settingsSoundsTitle => 'Звук';

  @override
  String get settingsMusicLabel => 'Фонова музика';

  @override
  String get settingsSoundEffectsLabel => 'Звукови ефекти';

  @override
  String get settingsPausedGamesTitle => 'Игри на пауза';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Потвърждение преди изтриване на игра';

  @override
  String get settingsLanguageTitle => 'Език';

  @override
  String get settingsLanguageSystemOption => 'Език на телефона';

  @override
  String get diceOffTitle => 'Кой започва?';

  @override
  String get diceOffInstructions =>
      'Всеки хвърля по един зар: най-ниският резултат започва играта.';

  @override
  String diceOffTieBreak(String names) {
    return 'Равенство: $names хвърлят отново.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName хвърля зара';
  }

  @override
  String get diceOffRollButton => 'Хвърли зара';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName започва играта!';
  }

  @override
  String get gameOverTitle => 'Край на играта';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName печели!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Нова игра';

  @override
  String get passDeviceInstruction => 'Подай устройството на';

  @override
  String get readyButton => 'Готово';

  @override
  String get notEnteredLabel => '(не е влязъл)';

  @override
  String get opportunityTooltip =>
      'На 200 точки от зачеркването на играча точно отгоре!';

  @override
  String get dangerTooltip =>
      'Опасност: играчът точно отдолу е само на 200 точки, риск да те зачеркне';

  @override
  String get tiretTooltip => 'Черта: втори провал ще зачеркне резултата';

  @override
  String get previousScoreHadTiretTooltip => 'Предишният резултат имаше черта';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return 'Вероятност за отбелязване с $_temp0';
  }
}
