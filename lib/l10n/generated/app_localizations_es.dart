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
  String get pausedGamesSectionLabel => 'Runs interrumpidas';

  @override
  String get finishedRunsSectionLabel => 'Runs terminadas';

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
  String get leaveGameTooltip => 'Salir de la partida';

  @override
  String get scoreGridLabel => 'Tabla de puntuaciones';

  @override
  String get finalRoundBanner =>
      '¡Última ronda: un jugador ha alcanzado 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Puntos del turno: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Mínimo requerido: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Dados guardados este turno';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount dados',
      one: '$diceCount dado',
    );
    return '$playerName hereda $_temp0 del turno anterior.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Puntuación actual: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return 'Continuar con $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Retomar esta mano ya superaría 10000: no se puede plantar.';

  @override
  String get restartWithFreshDiceButton =>
      'Empezar de nuevo con 5 dados nuevos';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return 'Retomar con $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel =>
      'Empezar de nuevo con 5 dados nuevos';

  @override
  String get keepDiceButton => 'Guardar los dados';

  @override
  String get reRollFullHandButton => 'Relanzar (dados calientes)';

  @override
  String get stopButton => 'Plantarse';

  @override
  String get rollDiceButton => 'Lanzar los dados';

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
  String get continueButton => 'Continuar';

  @override
  String thisRollScoreLabel(int score) {
    return 'Puntos de esta tirada: $score';
  }

  @override
  String get howManyFivesToKeep => '¿Cuántos 5 quieres guardar?';

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
}
