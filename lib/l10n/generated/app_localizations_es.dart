// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get splashPresents => 'presenta';

  @override
  String get ownerNameDialogTitle => '¿Cuál es tu nombre?';

  @override
  String get ownerNameFieldLabel => 'Nombre del jugador principal';

  @override
  String get laterButton => 'Más tarde';

  @override
  String get validateButton => 'Confirmar';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String playersCountTitle(int count) {
    return 'Jugadores ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Jugador $number';
  }

  @override
  String get unnamedPlayerFallback => 'Jugador';

  @override
  String playerNameFieldLabel(int number) {
    return 'Nombre del jugador $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Añadir';

  @override
  String get removePlayerButton => 'Quitar';

  @override
  String get botDifficultyTitle => 'Dificultad de los bots';

  @override
  String get aiDifficultyCautious => 'Prudente';

  @override
  String get aiDifficultyBalanced => 'Equilibrado';

  @override
  String get aiDifficultyAggressive => 'Agresivo';

  @override
  String get startGameButton => 'Empezar partida';

  @override
  String get newGameSectionLabel => 'Nueva run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Runs interrumpidas ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Runs terminadas ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Aún no hay partidas en pausa.';

  @override
  String get noFinishedRunsMessage => 'Aún no hay runs terminadas.';

  @override
  String get deleteGameConfirmTitle => '¿Eliminar esta partida?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'La partida «$alias» se eliminará definitivamente.';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Salir de la partida';

  @override
  String get scoreGridLabel => 'Tabla de puntuaciones';

  @override
  String get finalRoundBanner =>
      '¡Última ronda: un jugador ha alcanzado 10000!';

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
      'Retomar esta mano ya superaría 10000: no se puede plantar.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel =>
      'Empezar de nuevo con 5 dados nuevos';

  @override
  String get keepDiceButton => 'Guardar los dados';

  @override
  String get stopButton => 'Plantarse';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return '$_temp0 por lanzar';
  }

  @override
  String get bustedTitle => '¡Te has pasado!';

  @override
  String get bustExceedsTarget => 'Esta tirada superaría 10000.';

  @override
  String get fullHandMustReroll => '¡Dados calientes: debes volver a tirar!';

  @override
  String get failureBelowMinimum => 'Puntuación insuficiente para plantarse.';

  @override
  String get failureEndsIn50 =>
      'No puedes plantarte con una puntuación que termine en 50.';

  @override
  String get failureMustContinueHotDice => 'Debes volver a tirar.';

  @override
  String get failureNotRolledYet =>
      'Debes lanzar los dados antes de poder plantarte.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Plantarte ahora haría imposible llegar exactamente a 10000.';

  @override
  String get settingsMainPlayerTitle => 'Jugador principal';

  @override
  String get settingsYourNameLabel => 'Tu nombre (propietario del dispositivo)';

  @override
  String get settingsDelaysTitle => 'Temporizaciones';

  @override
  String get settingsDelaysDescription =>
      'Retraso antes de que una acción automática se active sola. 0 para desactivar.';

  @override
  String get settingsAiDelayLabel => 'Mensajes de la IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Acciones automáticas del jugador humano (ms)';

  @override
  String get settingsDiceTitle => 'Dados';

  @override
  String get settingsDiceUniform => 'Uniforme';

  @override
  String get settingsDiceVaried => 'Variado';

  @override
  String get settingsSoundsTitle => 'Sonido';

  @override
  String get settingsMusicLabel => 'Música de fondo';

  @override
  String get settingsSoundEffectsLabel => 'Efectos de sonido';

  @override
  String get settingsPausedGamesTitle => 'Partidas en pausa';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmar antes de eliminar una partida';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSystemOption => 'Idioma del teléfono';

  @override
  String get diceOffTitle => '¿Quién empieza?';

  @override
  String get diceOffInstructions =>
      'Cada jugador lanza un dado: la puntuación más baja empieza la partida.';

  @override
  String diceOffTieBreak(String names) {
    return 'Empate: $names vuelven a tirar.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName lanza el dado';
  }

  @override
  String get diceOffRollButton => 'Lanzar el dado';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '¡$playerName empieza la partida!';
  }

  @override
  String get gameOverTitle => 'Fin de la partida';

  @override
  String winnerAnnouncement(String playerName) {
    return '¡$playerName gana!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Nueva partida';

  @override
  String get passDeviceInstruction => 'Pasa el dispositivo a';

  @override
  String get readyButton => 'Listo';

  @override
  String get notEnteredLabel => '(no ha entrado)';

  @override
  String get opportunityTooltip =>
      '¡A 200 puntos de tachar al jugador justo por encima!';

  @override
  String get dangerTooltip =>
      'Peligro: el jugador justo por debajo está a solo 200 puntos, riesgo de que te tache';

  @override
  String get tiretTooltip => 'Guion: un segundo pase tachará la puntuación';

  @override
  String get previousScoreHadTiretTooltip =>
      'La puntuación anterior tenía un guion';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return 'Probabilidad de puntuar con $_temp0';
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
