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
  String get validateButton => 'Confirmar';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get helpTooltip => 'Reglas del juego';

  @override
  String get aboutTooltip => 'Acerca de';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versión $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Cerrar';

  @override
  String playersCountTitle(int count) {
    return 'Jugadores ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Empezar partida';

  @override
  String get newGameSectionLabel => 'Nueva run...';

  @override
  String get resumeGamesButton => 'Reanudar partidas';

  @override
  String get managePlayersButton => 'Gestionar jugadores';

  @override
  String get finishedGamesButton => 'Últimas partidas terminadas';

  @override
  String get statisticsButton => 'Estadísticas';

  @override
  String playersScreenTitle(int count) {
    return 'Jugadores ($count)';
  }

  @override
  String get addPlayerTooltip => 'Añadir un jugador';

  @override
  String get noPlayersMessage => 'Aún no hay jugadores guardados.';

  @override
  String get newPlayerTitle => 'Nuevo jugador';

  @override
  String get editPlayerTitle => 'Editar jugador';

  @override
  String get playerNameLabel => 'Nombre';

  @override
  String get playerNicknameLabel => 'Apodo (opcional)';

  @override
  String get playerNameRequiredError => 'El nombre es obligatorio.';

  @override
  String get playerNameTakenError => 'Este nombre ya lo usa otro jugador.';

  @override
  String get deletePlayerConfirmTitle => '¿Eliminar este jugador?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'La ficha de «$name» y sus estadísticas se eliminarán definitivamente. Las partidas ya jugadas se conservan.';
  }

  @override
  String get statsSectionTime => 'Tiempo de juego';

  @override
  String get statsSectionGames => 'Partidas';

  @override
  String get statsSectionFigures => 'Combinaciones';

  @override
  String get statsSectionRolls => 'Turnos y tiradas';

  @override
  String get statsTurns => 'Turnos jugados';

  @override
  String get statsRolls => 'Tiradas';

  @override
  String get statsRollsPerTurn => 'Tiradas por turno';

  @override
  String get statsSectionMisc => 'Hazañas';

  @override
  String get statsTotalTime => 'Total';

  @override
  String get statsAverageTime => 'Media por partida';

  @override
  String get statsShortestTime => 'La más corta';

  @override
  String get statsLongestTime => 'La más larga';

  @override
  String get statsGamesPlayed => 'Jugadas';

  @override
  String get statsGamesWon => 'Ganadas';

  @override
  String get statsGamesLost => 'Perdidas';

  @override
  String get statsLoneAces => '1 sueltos guardados';

  @override
  String get statsLoneFives => '5 sueltos guardados';

  @override
  String get statsBrelans => 'Tríos';

  @override
  String get statsCarres => 'Póqueres';

  @override
  String get statsQuintes => 'Repóqueres';

  @override
  String get statsSuites => 'Escaleras';

  @override
  String get statsSmallSuites => 'de ellas bajas';

  @override
  String get statsBigSuites => 'de ellas altas';

  @override
  String get statsAceQuints => 'Cinco 1';

  @override
  String get statsAceQuintsWon => 'de ellos ganadores';

  @override
  String get statsBestTurn => 'Mejor turno';

  @override
  String get statsHotDiceRun => 'Dados calientes seguidos';

  @override
  String get statsBusts => 'Pases';

  @override
  String get statsLongestBustStreak => 'racha más larga';

  @override
  String get statsSelfBars => 'Tachados a sí mismo';

  @override
  String get statsBarsInflicted => 'Tachados a otros';

  @override
  String get scoreChartTitle => 'Evolución de las puntuaciones';

  @override
  String get gameStatsTitle => 'Estadísticas de la partida';

  @override
  String get gameStatsGameSection => 'Partida';

  @override
  String get gameStatsFiguresSection => 'Combinaciones de la partida';

  @override
  String get gameStatsDuration => 'Tiempo de juego';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turnos',
      one: '$turns turno',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts pases',
      one: '$busts pase',
    );
    return '$_temp0 · mejor $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games partidas',
      one: '$games partida',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won ganadas',
      one: '$won ganada',
    );
    return '$_temp0 · $_temp1 · mejor $best';
  }

  @override
  String get scoreChartEmpty =>
      'Aún no ha terminado ningún turno: no hay nada que trazar.';

  @override
  String get replayUnavailable =>
      'Esta partida no se puede volver a ver: su registro está incompleto.';

  @override
  String get replayPlay => 'Reproducir';

  @override
  String get replayPause => 'Pausa';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Turno $turn';
  }

  @override
  String get scoreChartXAxis => 'Turnos jugados';

  @override
  String get statsBreakdownRow => 'de ellos';

  @override
  String get statsRecordsTitle => 'Récords';

  @override
  String get statsNoRecordYet => 'Aún no hay récords.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Elegir jugadores';

  @override
  String get addHumanTooltip => 'Añadir un jugador';

  @override
  String get addBotTooltip => 'Añadir un bot';

  @override
  String get createPlayerButton => 'Nuevo jugador';

  @override
  String get noPlayersToPickMessage =>
      'No hay jugadores guardados. Crea uno para empezar.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Quitar de la partida';

  @override
  String get notEnoughPlayersMessage => 'Hacen falta al menos dos jugadores.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partidas jugadas',
      one: '$count partida jugada',
      zero: 'Ninguna partida jugada',
    );
    return '$_temp0';
  }

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
  String get gameRunParticipantsSeparator => ' vs ';

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
  String get resumeLastGameDialogTitle => '¿Reanudar la partida?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Hay una partida «$alias» en curso. ¿Quieres reanudarla?';
  }

  @override
  String get resumeGameButton => 'Reanudar';

  @override
  String get gameOverReplayButton => 'Volver a ver la partida';

  @override
  String get scoreGridLabel => 'Tabla de puntuaciones';

  @override
  String get finalRoundBanner =>
      '¡Última ronda: un jugador ha alcanzado 10000!';

  @override
  String get currentRollZoneLabel => 'Pista';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Pista ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Mano actual';

  @override
  String get logHotDiceMessage => '¡Dados calientes!';

  @override
  String get logScoreCollisionMessage => 'Puntuación tachada:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return '$kept: $gain, $_temp0 => $total ptos';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, dados calientes => $total ptos';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score ptos anotados => $total ptos';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score ptos retomados';
  }

  @override
  String logBustTiretMessage(int score) {
    return '¡Te has pasado! => $score guion';
  }

  @override
  String get logBustBarredPrefix => '¡Te has pasado! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'vuelta a $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Retomar esta mano ya superaría 10000: no se puede plantar.';

  @override
  String get rollButton => 'Tirar';

  @override
  String get showProbabilitiesSetting => 'Mostrar probabilidades';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Muestra en el botón «Tirar» la probabilidad de sumar al menos un punto';

  @override
  String get stopButton => 'Plantarse';

  @override
  String get bustedTitle => '¡Te has pasado!';

  @override
  String get bustExceedsTarget => 'Esta tirada superaría 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Dados calientes en 10000: no puedes plantarte y volver a tirarlo todo te pasaría.';

  @override
  String get bustContinueButton => 'Continuar';

  @override
  String get inheritedHandDialogTitle => '¿Retomar?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Retomar la mano';

  @override
  String get newHandButton => 'Nueva mano';

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
  String get settingsHandednessLabel => 'Disposición de los botones';

  @override
  String get settingsHandednessRight => 'Diestro';

  @override
  String get settingsHandednessLeft => 'Zurdo';

  @override
  String get settingsControlsTitle => 'Controles';

  @override
  String get settingsShakeToRollLabel => 'Agitar para tirar los dados';

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
  String get reorderPlayersHint =>
      'Arrastra a un jugador por su asa para cambiar el orden alrededor de la mesa.';

  @override
  String get reorderPlayerHandleLabel => 'Mover a este jugador';

  @override
  String get diceOffTitle => '¿Quién empieza?';

  @override
  String get diceOffInstructions =>
      'Todos lanzan su dado a la vez: empieza el más bajo. En caso de empate, los empatados vuelven a lanzar.';

  @override
  String diceOffTieBreak(String names) {
    return 'Empate: $names vuelven a tirar.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '¡$playerName empieza la partida!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Orden de juego';

  @override
  String get diceOffReversedNote =>
      'Duelo entre vecinos ganado por el segundo: la partida gira en sentido contrario.';

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
  String get rankFirstTooltip => 'En cabeza';

  @override
  String get rankSecondTooltip => '2.º en puntuación';

  @override
  String get rankThirdTooltip => '3.º en puntuación';

  @override
  String get rulesScreenTitle => 'Reglas del juego';

  @override
  String get rulesGoalTitle => 'Objetivo del juego';

  @override
  String get rulesGoalBody =>
      'El primer jugador que alcanza exactamente 10 000 puntos gana la partida. Hay que llegar a esa cifra justa: pasarse no cuenta.';

  @override
  String get rulesTurnTitle => 'Cómo se juega un turno';

  @override
  String get rulesTurnBody =>
      'En tu turno, tiras 5 dados. Algunos valores dan puntos (ver más abajo), otros no sirven de nada. Apartas al menos un dado que puntúe y luego eliges: volver a tirar los dados restantes para intentar sumar más puntos, o plantarte y anotar lo acumulado en este turno. Si una tirada no da ningún punto, es un pase (ver más abajo) y pierdes todo lo acumulado en este turno.';

  @override
  String get rulesScoringTitle => 'Qué da puntos';

  @override
  String get rulesScoringBody =>
      '• Un 1 suelto: 100 puntos. Un 5 suelto: 50 puntos. Los demás valores sueltos (2, 3, 4, 6) no dan nada.\n• Tres dados iguales: 1000 puntos por tres 1, si no el valor del dado × 100 (tres 4 valen 400, tres 6 valen 600).\n• Un cuarto dado del mismo valor añade 1000 puntos más.\n• Cinco dados iguales valen el valor del dado × 1000, salvo cinco 1, que dan directamente 10 000 puntos: la victoria inmediata.\n• Una escalera de 5 dados consecutivos (1-2-3-4-5 o 2-3-4-5-6) vale 500 puntos.';

  @override
  String get rulesHotDiceTitle =>
      'Dados calientes: una segunda oportunidad forzada';

  @override
  String get rulesHotDiceBody =>
      'Si todos los dados que acabas de tirar dan puntos, debes volver a tirar los 5 dados: no puedes plantarte en ese preciso momento. Es lo que se llama «dados calientes».';

  @override
  String get rulesBustTitle => 'El pase';

  @override
  String get rulesBustBody =>
      'Si una tirada no da ningún punto, tu turno termina en el acto y pierdes todos los puntos acumulados en este turno (lo que ya anotaste en turnos anteriores se conserva). Un pase marca además tu línea de puntuación actual con un guion; si ya tenía uno, se tacha y tu puntuación vuelve a su valor anterior.';

  @override
  String get rulesEntryTitle => 'Entrar en la partida';

  @override
  String get rulesEntryBody =>
      'Para empezar a sumar, tu primer turno con éxito debe darte al menos 500 puntos. Una vez dentro de la partida, cada turno siguiente debe darte al menos 200 puntos para poder plantarte.';

  @override
  String get rulesNoFiftyTitle => 'Nunca una puntuación que acabe en 50';

  @override
  String get rulesNoFiftyBody =>
      'Nunca puedes elegir plantarte con un total de turno que acabe en 50 (como 250 o 450): hay que seguir tirando hasta obtener un total válido.';

  @override
  String get rulesExtensionTitle => 'La regla de extensión';

  @override
  String get rulesExtensionBody =>
      'Una vez que has anotado un trío o un póquer de un valor (por ejemplo tres 4), cualquier dado suelto de ese mismo valor que salga más tarde en el mismo turno vale 100 puntos en lugar de su valor habitual — incluido un 5 suelto, que entonces vale 100 en lugar de 50. Esta ventaja desaparece en cuanto consigues dados calientes.';

  @override
  String get rulesInheritTitle => 'Heredar los dados del jugador anterior';

  @override
  String get rulesInheritBody =>
      'Cuando un jugador se planta con dados aún sin tirar, el siguiente jugador puede elegir retomar esos dados restantes junto con la puntuación ya acumulada como base, o empezar de cero con 5 dados nuevos. Tras un pase, en cambio, el siguiente jugador siempre empieza con 5 dados nuevos, sin heredar nada.';

  @override
  String get rulesBarredTitle => 'Guion y tachado';

  @override
  String get rulesBarredBody =>
      'Un pase coloca un guion de aviso en tu línea de puntuación actual si aún no lo tiene. Si ya lo tiene, la línea se tacha y tu puntuación vuelve a su valor anterior. Si tu puntuación alcanza exactamente el mismo total que la de otro jugador, a este se le tacha de la misma manera, tenga ya un guion o no.';

  @override
  String get rulesVictoryTitle => 'Cómo ganar';

  @override
  String get rulesVictoryBody =>
      'El primer jugador que alcanza exactamente 10 000 puntos desencadena una ronda final: cada uno de los demás jugadores tiene una última oportunidad de igualarlo o superarlo en su turno. Si otro jugador alcanza también exactamente 10 000 durante esa ronda final, se queda con la corona y empieza una nueva ronda final a su alrededor.';

  @override
  String get onlinePlayButton => 'Jugar en línea';

  @override
  String get onlineResumeButton => 'Reanudar la partida en línea';

  @override
  String get onlineTitle => 'Partida en línea';

  @override
  String get onlineNameLabel => 'Tu apodo';

  @override
  String get onlineCreateButton => 'Crear una sala';

  @override
  String get onlineJoinButton => 'Unirse';

  @override
  String get onlineCodeLabel => 'Código de la sala';

  @override
  String get onlineOrDivider => 'o';

  @override
  String get onlineShareHint =>
      'Da este código a los demás jugadores para que se unan.';

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Jugadores ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Anfitrión';

  @override
  String get onlineDisconnectedBadge => 'Desconectado';

  @override
  String get onlineNeedTwoPlayers =>
      'Se necesitan al menos 2 jugadores, todos conectados.';

  @override
  String get onlineWaitingForHost => 'Esperando a que el anfitrión empiece…';

  @override
  String get onlineLeaveButton => 'Salir';

  @override
  String get onlineLeaveConfirmTitle => '¿Salir de la partida en línea?';

  @override
  String get onlineLeaveConfirmBody =>
      'En una partida ya empezada, tu sitio quedará vacío y la partida esperará a que vuelvas.';

  @override
  String get onlineConnecting => 'Conectando con el servidor…';

  @override
  String get onlineReconnecting => 'Conexión perdida, reconectando…';

  @override
  String get onlineSuspended =>
      'Partida suspendida: un jugador lleva demasiado tiempo ausente.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName está jugando…';
  }

  @override
  String get onlineDiceOffContinue => 'Jugar';

  @override
  String get onlineErrorUnreachable => 'Servidor inaccesible.';

  @override
  String get onlineErrorRoomNotFound => 'No hay ninguna sala con este código.';

  @override
  String get onlineErrorRoomFull => 'Esta sala está llena.';

  @override
  String get onlineErrorGameStarted => 'Esta partida ya ha empezado.';

  @override
  String get onlineErrorRateLimited =>
      'Demasiados intentos: vuelve a probar en un momento.';

  @override
  String get onlineErrorBadToken => 'Tu sitio en esta sala ya no existe.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Actualiza la aplicación para jugar en línea.';

  @override
  String get onlineErrorGeneric => 'Se ha producido un error.';
}
