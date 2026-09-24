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
  String get validateButton => 'Потвърди';

  @override
  String get settingsTooltip => 'Настройки';

  @override
  String get helpTooltip => 'Правила на играта';

  @override
  String get aboutTooltip => 'Относно';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Версия $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Затвори';

  @override
  String playersCountTitle(int count) {
    return 'Играчи ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Започни играта';

  @override
  String get newGameSectionLabel => 'Нов run...';

  @override
  String get resumeGamesButton => 'Продължаване на игри';

  @override
  String get managePlayersButton => 'Управление на играчите';

  @override
  String get finishedGamesButton => 'Последни завършени игри';

  @override
  String get statisticsButton => 'Статистика';

  @override
  String playersScreenTitle(int count) {
    return 'Играчи ($count)';
  }

  @override
  String get addPlayerTooltip => 'Добави играч';

  @override
  String get noPlayersMessage => 'Все още няма записани играчи.';

  @override
  String get newPlayerTitle => 'Нов играч';

  @override
  String get editPlayerTitle => 'Редактиране на играч';

  @override
  String get playerNameLabel => 'Име';

  @override
  String get playerNicknameLabel => 'Прякор (по избор)';

  @override
  String get playerNameRequiredError => 'Името е задължително.';

  @override
  String get playerNameTakenError => 'Това име вече се използва от друг играч.';

  @override
  String get deletePlayerConfirmTitle => 'Изтриване на този играч?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Профилът на „$name“ и статистиката му ще бъдат окончателно изтрити. Вече изиграните игри се запазват.';
  }

  @override
  String get statsSectionTime => 'Време за игра';

  @override
  String get statsSectionGames => 'Игри';

  @override
  String get statsSectionFigures => 'Комбинации';

  @override
  String get statsSectionRolls => 'Ходове и хвърляния';

  @override
  String get statsTurns => 'Изиграни ходове';

  @override
  String get statsRolls => 'Хвърляния';

  @override
  String get statsRollsPerTurn => 'Хвърляния на ход';

  @override
  String get statsSectionMisc => 'Подвизи';

  @override
  String get statsTotalTime => 'Общо';

  @override
  String get statsAverageTime => 'Средно на игра';

  @override
  String get statsShortestTime => 'Най-кратка';

  @override
  String get statsLongestTime => 'Най-дълга';

  @override
  String get statsGamesPlayed => 'Изиграни';

  @override
  String get statsGamesWon => 'Спечелени';

  @override
  String get statsGamesLost => 'Загубени';

  @override
  String get statsLoneAces => 'Запазени единични 1';

  @override
  String get statsLoneFives => 'Запазени единични 5';

  @override
  String get statsBrelans => 'Тройки';

  @override
  String get statsCarres => 'Каре';

  @override
  String get statsQuintes => 'Пет еднакви';

  @override
  String get statsSuites => 'Кентове';

  @override
  String get statsSmallSuites => 'от тях малки';

  @override
  String get statsBigSuites => 'от тях големи';

  @override
  String get statsAceQuints => 'Пет единици';

  @override
  String get statsAceQuintsWon => 'от тях печеливши';

  @override
  String get statsBestTurn => 'Най-добър ход';

  @override
  String get statsHotDiceRun => 'Горещи зарове подред';

  @override
  String get statsBusts => 'Провали';

  @override
  String get statsLongestBustStreak => 'най-дълга серия';

  @override
  String get statsSelfBars => 'Зачеркнати сами';

  @override
  String get statsBarsInflicted => 'Зачеркнати други';

  @override
  String get scoreChartTitle => 'Развитие на резултатите';

  @override
  String get gameStatsTitle => 'Статистика на играта';

  @override
  String get gameStatsGameSection => 'Игра';

  @override
  String get gameStatsFiguresSection => 'Комбинации в играта';

  @override
  String get gameStatsDuration => 'Време за игра';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns хода',
      one: '$turns ход',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts провала',
      one: '$busts провал',
    );
    return '$_temp0 · най-добър $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games игри',
      one: '$games игра',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won спечелени',
      one: '$won спечелена',
    );
    return '$_temp0 · $_temp1 · най-добър $best';
  }

  @override
  String get scoreChartEmpty =>
      'Все още няма завършен ход: няма какво да се начертае.';

  @override
  String get replayUnavailable =>
      'Тази игра не може да бъде преиграна: дневникът ѝ е непълен.';

  @override
  String get replayPlay => 'Пусни';

  @override
  String get replayPause => 'Пауза';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Ход $turn';
  }

  @override
  String get scoreChartXAxis => 'Изиграни ходове';

  @override
  String get statsBreakdownRow => 'от тях';

  @override
  String get statsRecordsTitle => 'Рекорди';

  @override
  String get statsNoRecordYet => 'Все още няма рекорди.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Избор на играчи';

  @override
  String get addHumanTooltip => 'Добави играч';

  @override
  String get addBotTooltip => 'Добави бот';

  @override
  String get createPlayerButton => 'Нов играч';

  @override
  String get noPlayersToPickMessage =>
      'Няма записани играчи. Създайте един, за да започнете.';

  @override
  String get botLabel => 'Бот';

  @override
  String get removeSeatTooltip => 'Премахни от играта';

  @override
  String get notEnoughPlayersMessage => 'Нужни са поне двама играчи.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изиграни игри',
      one: '$count изиграна игра',
      zero: 'Няма изиграни игри',
    );
    return '$_temp0';
  }

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
  String get gameRunParticipantsSeparator => ' срещу ';

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
  String get resumeLastGameDialogTitle => 'Продължаване на играта?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Игра „$alias“ е в ход. Искате ли да я продължите?';
  }

  @override
  String get resumeGameButton => 'Продължи';

  @override
  String get gameOverReplayButton => 'Преглед на играта';

  @override
  String get scoreGridLabel => 'Таблица с резултати';

  @override
  String get finalRoundBanner => 'Последен рунд: играч достигна 10000!';

  @override
  String get currentRollZoneLabel => 'Писта';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Писта ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Текуща ръка';

  @override
  String get logHotDiceMessage => 'Горещи зарове!';

  @override
  String get logScoreCollisionMessage => 'Зачеркнат резултат:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return '$kept: $gain, $_temp0 => $total т.';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, горещи зарове => $total т.';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score т. записани => $total т.';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score т. поети';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Изгоря! => $score черта';
  }

  @override
  String get logBustBarredPrefix => 'Изгоря! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'обратно на $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Поемането на тази ръка вече би надвишило 10000: не може да запишеш резултата.';

  @override
  String get rollButton => 'Хвърли';

  @override
  String get showProbabilitiesSetting => 'Показване на вероятностите';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Показва на бутона „Хвърли“ шанса да вкарате поне една точка';

  @override
  String get stopButton => 'Спри се';

  @override
  String get bustedTitle => 'Изгоря!';

  @override
  String get bustExceedsTarget => 'Това хвърляне би надвишило 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Горещи зарове на 10000: не можете да спрете, а хвърлянето на всичко отново би надвишило.';

  @override
  String get bustContinueButton => 'Продължи';

  @override
  String get inheritedHandDialogTitle => 'Поемане?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count зара',
      one: '$count зар',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Поеми ръката';

  @override
  String get newHandButton => 'Нова ръка';

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
  String get settingsHandednessLabel => 'Разположение на бутоните';

  @override
  String get settingsHandednessRight => 'Десняк';

  @override
  String get settingsHandednessLeft => 'Левичар';

  @override
  String get settingsControlsTitle => 'Управление';

  @override
  String get settingsShakeToRollLabel => 'Разклатете, за да хвърлите заровете';

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
  String get reorderPlayersHint =>
      'Плъзнете играч за дръжката му, за да промените реда около масата.';

  @override
  String get reorderPlayerHandleLabel => 'Преместване на този играч';

  @override
  String get diceOffTitle => 'Кой започва?';

  @override
  String get diceOffInstructions =>
      'Всички хвърлят зара си едновременно: започва най-ниският. При равенство изравнените хвърлят отново.';

  @override
  String diceOffTieBreak(String names) {
    return 'Равенство: $names хвърлят отново.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName започва играта!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Ред на игра';

  @override
  String get diceOffReversedNote =>
      'Дуел между съседи, спечелен от втория: играта върви в обратна посока.';

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
  String get rankFirstTooltip => 'Води';

  @override
  String get rankSecondTooltip => '2-ри по точки';

  @override
  String get rankThirdTooltip => '3-ти по точки';

  @override
  String get rulesScreenTitle => 'Правила на играта';

  @override
  String get rulesGoalTitle => 'Цел на играта';

  @override
  String get rulesGoalBody =>
      'Първият играч, достигнал точно 10 000 точки, печели играта. Трябва да уцелите точно това число: надхвърлянето не се брои.';

  @override
  String get rulesTurnTitle => 'Как се играе един ход';

  @override
  String get rulesTurnBody =>
      'На своя ход хвърляте 5 зара. Някои стойности носят точки (вижте по-долу), други не носят нищо. Отделяте поне един точкуващ зар и после избирате: да хвърлите отново останалите зарове, за да съберете още точки, или да спрете и да запишете натрупаното през този ход. Ако едно хвърляне не донесе нито една точка, това е провал (вижте по-долу) и губите всичко натрупано през този ход.';

  @override
  String get rulesScoringTitle => 'Какво носи точки';

  @override
  String get rulesScoringBody =>
      '• Единична 1: 100 точки. Единична 5: 50 точки. Другите единични стойности (2, 3, 4, 6) не носят нищо.\n• Три еднакви зара: 1000 точки за три единици, иначе стойността на зара × 100 (три четворки са 400, три шестици — 600).\n• Четвърти зар със същата стойност добавя още 1000 точки.\n• Пет еднакви зара струват стойността на зара × 1000, освен пет единици, които носят направо 10 000 точки: незабавна победа.\n• Кент от 5 последователни зара (1-2-3-4-5 или 2-3-4-5-6) струва 500 точки.';

  @override
  String get rulesHotDiceTitle => 'Горещи зарове: принудителен втори шанс';

  @override
  String get rulesHotDiceBody =>
      'Ако всички зарове, които току-що хвърлихте, носят точки, трябва да хвърлите отново всичките 5 зара: не можете да спрете точно в този момент. Това се нарича „горещи зарове“.';

  @override
  String get rulesBustTitle => 'Провалът';

  @override
  String get rulesBustBody =>
      'Ако едно хвърляне не донесе абсолютно никакви точки, ходът ви приключва веднага и губите всички точки, натрупани през този ход (записаното в предишните ходове остава). Провалът освен това отбелязва текущия ви ред в резултатите с черта; ако вече е имал такава, редът се зачерква и резултатът ви се връща към предишната стойност.';

  @override
  String get rulesEntryTitle => 'Влизане в играта';

  @override
  String get rulesEntryBody =>
      'За да започнете да трупате точки, първият ви успешен ход трябва да донесе поне 500 точки. След като влезете в играта, всеки следващ ход трябва да донесе поне 200 точки, за да можете да спрете.';

  @override
  String get rulesNoFiftyTitle => 'Никога резултат, завършващ на 50';

  @override
  String get rulesNoFiftyBody =>
      'Никога не можете да изберете доброволно да спрете при сбор за хода, завършващ на 50 (например 250 или 450): трябва да хвърляте отново, докато получите валиден сбор.';

  @override
  String get rulesExtensionTitle => 'Правилото за разширение';

  @override
  String get rulesExtensionBody =>
      'След като сте записали тройка или каре с дадена стойност (например три четворки), всеки единичен зар със същата стойност, паднал по-късно в същия ход, носи 100 точки вместо обичайната си стойност — включително единична 5, която тогава струва 100 вместо 50. Това предимство изчезва веднага щом получите горещи зарове.';

  @override
  String get rulesInheritTitle => 'Наследяване на заровете на предишния играч';

  @override
  String get rulesInheritBody =>
      'Когато играч спре доброволно, като все още има нехвърлени зарове, следващият играч може да избере да поеме тези оставащи зарове заедно с вече натрупания резултат като начална база, или да започне от нулата с 5 нови зара. След провал обаче следващият играч винаги започва с 5 нови зара, без да наследява нищо.';

  @override
  String get rulesBarredTitle => 'Черта и зачеркване';

  @override
  String get rulesBarredBody =>
      'Провалът поставя предупредителна черта на текущия ви ред в резултатите, ако той още няма такава. Ако вече има, редът се зачерква и резултатът ви се връща към предишната стойност. Ако резултатът ви стане точно равен на този на друг играч, той бива зачеркнат по същия начин, независимо дали вече има черта.';

  @override
  String get rulesVictoryTitle => 'Как се печели';

  @override
  String get rulesVictoryBody =>
      'Първият играч, достигнал точно 10 000 точки, задейства финален кръг: всеки от останалите играчи има последен шанс да го изравни или надмине на своя ход. Ако по време на финалния кръг друг играч също достигне точно 10 000, той поема короната и около него започва нов финален кръг.';
}
