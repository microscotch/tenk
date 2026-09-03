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
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Напусни играта';

  @override
  String get scoreGridLabel => 'Таблица с резултати';

  @override
  String get finalRoundBanner => 'Последен рунд: играч достигна 10000!';

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
      'Поемането на тази ръка вече би надвишило 10000: не може да запишеш резултата.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel => 'Започни отначало с 5 нови зара';

  @override
  String get keepDiceButton => 'Запази заровете';

  @override
  String get stopButton => 'Спри се';

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
