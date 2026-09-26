// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get splashPresents => 'presenta';

  @override
  String get validateButton => 'Conferma';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String get helpTooltip => 'Regole del gioco';

  @override
  String get aboutTooltip => 'Informazioni';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versione $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Chiudi';

  @override
  String playersCountTitle(int count) {
    return 'Giocatori ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Inizia partita';

  @override
  String get newGameSectionLabel => 'Nuova run...';

  @override
  String get resumeGamesButton => 'Riprendi partite';

  @override
  String get managePlayersButton => 'Gestione giocatori';

  @override
  String get finishedGamesButton => 'Ultime partite terminate';

  @override
  String get statisticsButton => 'Statistiche';

  @override
  String playersScreenTitle(int count) {
    return 'Giocatori ($count)';
  }

  @override
  String get addPlayerTooltip => 'Aggiungi un giocatore';

  @override
  String get noPlayersMessage => 'Nessun giocatore registrato per ora.';

  @override
  String get newPlayerTitle => 'Nuovo giocatore';

  @override
  String get editPlayerTitle => 'Modifica giocatore';

  @override
  String get playerNameLabel => 'Nome';

  @override
  String get playerNicknameLabel => 'Soprannome (facoltativo)';

  @override
  String get playerNameRequiredError => 'Il nome è obbligatorio.';

  @override
  String get playerNameTakenError =>
      'Questo nome è già usato da un altro giocatore.';

  @override
  String get deletePlayerConfirmTitle => 'Eliminare questo giocatore?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'La scheda di «$name» e le sue statistiche saranno eliminate definitivamente. Le partite già giocate vengono conservate.';
  }

  @override
  String get statsSectionTime => 'Tempo di gioco';

  @override
  String get statsSectionGames => 'Partite';

  @override
  String get statsSectionFigures => 'Combinazioni';

  @override
  String get statsSectionRolls => 'Turni e lanci';

  @override
  String get statsTurns => 'Turni giocati';

  @override
  String get statsRolls => 'Lanci';

  @override
  String get statsRollsPerTurn => 'Lanci per turno';

  @override
  String get statsSectionMisc => 'Imprese';

  @override
  String get statsTotalTime => 'Totale';

  @override
  String get statsAverageTime => 'Media per partita';

  @override
  String get statsShortestTime => 'La più breve';

  @override
  String get statsLongestTime => 'La più lunga';

  @override
  String get statsGamesPlayed => 'Giocate';

  @override
  String get statsGamesWon => 'Vinte';

  @override
  String get statsGamesLost => 'Perse';

  @override
  String get statsLoneAces => '1 singoli tenuti';

  @override
  String get statsLoneFives => '5 singoli tenuti';

  @override
  String get statsBrelans => 'Tris';

  @override
  String get statsCarres => 'Poker';

  @override
  String get statsQuintes => 'Cinque uguali';

  @override
  String get statsSuites => 'Scale';

  @override
  String get statsSmallSuites => 'di cui basse';

  @override
  String get statsBigSuites => 'di cui alte';

  @override
  String get statsAceQuints => 'Cinque 1';

  @override
  String get statsAceQuintsWon => 'di cui vincenti';

  @override
  String get statsBestTurn => 'Miglior turno';

  @override
  String get statsHotDiceRun => 'Dadi bollenti di fila';

  @override
  String get statsBusts => 'Sballi';

  @override
  String get statsLongestBustStreak => 'serie più lunga';

  @override
  String get statsSelfBars => 'Auto-cancellati';

  @override
  String get statsBarsInflicted => 'Cancellati ad altri';

  @override
  String get scoreChartTitle => 'Andamento dei punteggi';

  @override
  String get gameStatsTitle => 'Statistiche della partita';

  @override
  String get gameStatsGameSection => 'Partita';

  @override
  String get gameStatsFiguresSection => 'Combinazioni della partita';

  @override
  String get gameStatsDuration => 'Tempo di gioco';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turni',
      one: '$turns turno',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts sballi',
      one: '$busts sballo',
    );
    return '$_temp0 · migliore $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games partite',
      one: '$games partita',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won vinte',
      one: '$won vinta',
    );
    return '$_temp0 · $_temp1 · migliore $best';
  }

  @override
  String get scoreChartEmpty =>
      'Nessun turno ancora concluso: non c\'è ancora nulla da tracciare.';

  @override
  String get replayUnavailable =>
      'Questa partita non può essere rivista: il suo registro è incompleto.';

  @override
  String get replayPlay => 'Riproduci';

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
  String get scoreChartXAxis => 'Turni giocati';

  @override
  String get statsBreakdownRow => 'di cui';

  @override
  String get statsRecordsTitle => 'Record';

  @override
  String get statsNoRecordYet => 'Nessun record per ora.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Scegli i giocatori';

  @override
  String get addHumanTooltip => 'Aggiungi un giocatore';

  @override
  String get addBotTooltip => 'Aggiungi un bot';

  @override
  String get createPlayerButton => 'Nuovo giocatore';

  @override
  String get noPlayersToPickMessage =>
      'Nessun giocatore registrato. Creane uno per iniziare.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Togli dalla partita';

  @override
  String get notEnoughPlayersMessage => 'Servono almeno due giocatori.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count partite giocate',
      one: '$count partita giocata',
      zero: 'Nessuna partita giocata',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Run interrotte ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Run terminate ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Nessuna partita in pausa per ora.';

  @override
  String get noFinishedRunsMessage => 'Nessuna run terminata per ora.';

  @override
  String get gameRunParticipantsSeparator => ' vs ';

  @override
  String get deleteGameConfirmTitle => 'Eliminare questa partita?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'La partita «$alias» sarà eliminata definitivamente.';
  }

  @override
  String get cancelButton => 'Annulla';

  @override
  String get deleteButton => 'Elimina';

  @override
  String get resumeLastGameDialogTitle => 'Riprendere la partita?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Una partita «$alias» è in corso. Vuoi riprenderla?';
  }

  @override
  String get resumeGameButton => 'Riprendi';

  @override
  String get gameOverReplayButton => 'Rivedi la partita';

  @override
  String get scoreGridLabel => 'Tabellone dei punteggi';

  @override
  String get finalRoundBanner =>
      'Ultimo giro: un giocatore ha raggiunto 10000!';

  @override
  String get currentRollZoneLabel => 'Pista';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Pista ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Mano corrente';

  @override
  String get logHotDiceMessage => 'Dadi bollenti!';

  @override
  String get logScoreCollisionMessage => 'Punteggio cancellato:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return '$kept: $gain, $_temp0 => $total pt';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, dadi bollenti => $total pt';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score pt incassati => $total pt';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score pt ripresi';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Sballato! => $score trattino';
  }

  @override
  String get logBustBarredPrefix => 'Sballato! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'ritorno a $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Riprendere questa mano supererebbe già 10000: impossibile fermarsi.';

  @override
  String get rollButton => 'Lancia';

  @override
  String get showProbabilitiesSetting => 'Mostra le probabilità';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Mostra sul pulsante «Lancia» la probabilità di segnare almeno un punto';

  @override
  String get stopButton => 'Fermati';

  @override
  String get bustedTitle => 'Hai sballato!';

  @override
  String get bustExceedsTarget => 'Questo lancio supererebbe 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Dadi bollenti a 10000: impossibile fermarsi, e rilanciare tutto supererebbe.';

  @override
  String get bustContinueButton => 'Continua';

  @override
  String get inheritedHandDialogTitle => 'Riprendere?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Riprendi la mano';

  @override
  String get newHandButton => 'Nuova mano';

  @override
  String get failureBelowMinimum => 'Punteggio insufficiente per fermarsi.';

  @override
  String get failureEndsIn50 =>
      'Non puoi fermarti con un punteggio che finisce in 50.';

  @override
  String get failureMustContinueHotDice => 'Devi rilanciare.';

  @override
  String get failureNotRolledYet =>
      'Devi lanciare i dadi prima di poterti fermare.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Fermarti ora renderebbe impossibile raggiungere esattamente 10000.';

  @override
  String get settingsMainPlayerTitle => 'Giocatore principale';

  @override
  String get settingsYourNameLabel =>
      'Il tuo nome (proprietario del dispositivo)';

  @override
  String get settingsDelaysTitle => 'Temporizzazioni';

  @override
  String get settingsDelaysDescription =>
      'Ritardo prima che un\'azione automatica si attivi da sola. 0 per disattivare.';

  @override
  String get settingsAiDelayLabel => 'Messaggi IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Azioni automatiche del giocatore umano (ms)';

  @override
  String get settingsDiceTitle => 'Dadi';

  @override
  String get settingsDiceUniform => 'Uniforme';

  @override
  String get settingsDiceVaried => 'Variopinto';

  @override
  String get settingsSoundsTitle => 'Audio';

  @override
  String get settingsMusicLabel => 'Musica di sottofondo';

  @override
  String get settingsSoundEffectsLabel => 'Effetti sonori';

  @override
  String get settingsHandednessLabel => 'Disposizione dei pulsanti';

  @override
  String get settingsHandednessRight => 'Destrorso';

  @override
  String get settingsHandednessLeft => 'Mancino';

  @override
  String get settingsControlsTitle => 'Controlli';

  @override
  String get settingsShakeToRollLabel => 'Scuoti per lanciare i dadi';

  @override
  String get settingsPausedGamesTitle => 'Partite in pausa';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Conferma prima di eliminare una partita';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsLanguageSystemOption => 'Lingua del telefono';

  @override
  String get reorderPlayersHint =>
      'Trascina un giocatore dalla sua maniglia per cambiare l\'ordine attorno al tavolo.';

  @override
  String get reorderPlayerHandleLabel => 'Sposta questo giocatore';

  @override
  String get diceOffTitle => 'Chi inizia?';

  @override
  String get diceOffInstructions =>
      'Tutti lanciano il dado contemporaneamente: inizia il più basso. In caso di parità, i pari merito rilanciano.';

  @override
  String diceOffTieBreak(String names) {
    return 'Parità: $names rilanciano.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName inizia la partita!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Ordine di gioco';

  @override
  String get diceOffReversedNote =>
      'Duello tra vicini vinto dal secondo: la partita gira in senso inverso.';

  @override
  String get gameOverTitle => 'Fine della partita';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vince!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Passa il dispositivo a';

  @override
  String get readyButton => 'Pronto';

  @override
  String get notEnteredLabel => '(non entrato)';

  @override
  String get opportunityTooltip =>
      'A 200 punti dal cancellare il giocatore appena sopra!';

  @override
  String get dangerTooltip =>
      'Pericolo: il giocatore appena sotto è a soli 200 punti, rischia di cancellarti';

  @override
  String get tiretTooltip =>
      'Trattino: un secondo sballo cancellerà il punteggio';

  @override
  String get previousScoreHadTiretTooltip =>
      'Il punteggio precedente aveva un trattino';

  @override
  String get rankFirstTooltip => 'In testa';

  @override
  String get rankSecondTooltip => '2° per punteggio';

  @override
  String get rankThirdTooltip => '3° per punteggio';

  @override
  String get rulesScreenTitle => 'Regole del gioco';

  @override
  String get rulesGoalTitle => 'Scopo del gioco';

  @override
  String get rulesGoalBody =>
      'Il primo giocatore che raggiunge esattamente 10.000 punti vince la partita. Bisogna centrare quel numero preciso: superarlo non conta.';

  @override
  String get rulesTurnTitle => 'Come si gioca un turno';

  @override
  String get rulesTurnBody =>
      'Al tuo turno lanci 5 dadi. Alcuni valori danno punti (vedi sotto), altri non valgono nulla. Metti da parte almeno un dado che fa punti, poi scegli: rilanciare i dadi rimanenti per cercare di accumulare altri punti, oppure fermarti e incassare quanto accumulato in questo turno. Se un lancio non fa alcun punto, è uno sballo (vedi sotto) e perdi tutto ciò che avevi accumulato in questo turno.';

  @override
  String get rulesScoringTitle => 'Cosa fa punti';

  @override
  String get rulesScoringBody =>
      '• Un 1 singolo: 100 punti. Un 5 singolo: 50 punti. Gli altri valori singoli (2, 3, 4, 6) non valgono nulla.\n• Tre dadi uguali: 1000 punti per tre 1, altrimenti il valore del dado × 100 (tre 4 valgono 400, tre 6 valgono 600).\n• Un quarto dado dello stesso valore aggiunge altri 1000 punti.\n• Cinque dadi uguali valgono il valore del dado × 1000, tranne cinque 1, che danno subito 10.000 punti: la vittoria immediata.\n• Una scala di 5 dadi consecutivi (1-2-3-4-5 o 2-3-4-5-6) vale 500 punti.';

  @override
  String get rulesHotDiceTitle =>
      'Dadi bollenti: una seconda possibilità obbligata';

  @override
  String get rulesHotDiceBody =>
      'Se tutti i dadi che hai appena lanciato fanno punti, devi rilanciare tutti e 5 i dadi: non puoi fermarti proprio in quel momento. Si parla di «dadi bollenti».';

  @override
  String get rulesBustTitle => 'Lo sballo';

  @override
  String get rulesBustBody =>
      'Se un lancio non fa alcun punto, il tuo turno finisce subito e perdi tutti i punti accumulati in questo turno (quanto hai già incassato nei turni precedenti resta acquisito). Uno sballo segna inoltre la tua riga di punteggio attuale con un trattino; se ne aveva già uno, viene cancellata e il tuo punteggio torna al valore precedente.';

  @override
  String get rulesEntryTitle => 'Entrare in partita';

  @override
  String get rulesEntryBody =>
      'Per cominciare a segnare, il tuo primissimo turno riuscito deve fruttare almeno 500 punti. Una volta entrato in partita, ogni turno successivo deve fruttare almeno 200 punti per poterti fermare.';

  @override
  String get rulesNoFiftyTitle => 'Mai un punteggio che finisce per 50';

  @override
  String get rulesNoFiftyBody =>
      'Non puoi mai scegliere di fermarti volontariamente su un totale di turno che finisce per 50 (come 250 o 450): devi rilanciare finché non ottieni un totale valido.';

  @override
  String get rulesExtensionTitle => 'La regola dell\'estensione';

  @override
  String get rulesExtensionBody =>
      'Una volta incassato un tris o un poker di un certo valore (per esempio tre 4), ogni dado singolo di quello stesso valore uscito più avanti nello stesso turno vale 100 punti invece del suo valore abituale — compreso un 5 singolo, che vale allora 100 invece di 50. Questo vantaggio scompare non appena ottieni dadi bollenti.';

  @override
  String get rulesInheritTitle => 'Ereditare i dadi del giocatore precedente';

  @override
  String get rulesInheritBody =>
      'Quando un giocatore si ferma volontariamente avendo ancora dadi non lanciati, il giocatore successivo può scegliere di riprendere quei dadi rimanenti insieme al punteggio già accumulato come base di partenza, oppure di ripartire da zero con 5 dadi nuovi. Dopo uno sballo, invece, il giocatore successivo riparte sempre con 5 dadi nuovi, senza ereditare nulla.';

  @override
  String get rulesBarredTitle => 'Trattino e cancellato';

  @override
  String get rulesBarredBody =>
      'Uno sballo mette un trattino di avvertimento sulla tua riga di punteggio attuale se non ne ha già uno. Se ne ha già uno, la riga viene cancellata e il tuo punteggio torna al valore precedente. Se il tuo punteggio raggiunge esattamente lo stesso totale di un altro giocatore, quest\'ultimo viene cancellato allo stesso modo, che avesse già un trattino o no.';

  @override
  String get rulesVictoryTitle => 'Come si vince';

  @override
  String get rulesVictoryBody =>
      'Il primo giocatore che raggiunge esattamente 10.000 punti fa scattare un giro finale: ogni altro giocatore ha un\'ultima possibilità di eguagliarlo o superarlo al proprio turno. Se durante il giro finale anche un altro giocatore raggiunge esattamente 10.000, prende lui la corona e ricomincia un nuovo giro finale attorno a lui.';

  @override
  String get onlinePlayButton => 'Gioca online';

  @override
  String get onlineResumeButton => 'Riprendi la partita online';

  @override
  String get onlineTitle => 'Partita online';

  @override
  String get onlineNameLabel => 'Il tuo soprannome';

  @override
  String get onlineCreateButton => 'Crea una stanza';

  @override
  String get onlineJoinButton => 'Entra';

  @override
  String get onlineCodeLabel => 'Codice della stanza';

  @override
  String get onlineOrDivider => 'o';

  @override
  String get onlineShareHint =>
      'Dai questo codice agli altri giocatori perché ti raggiungano.';

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Giocatori ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Ospitante';

  @override
  String get onlineDisconnectedBadge => 'Disconnesso';

  @override
  String get onlineNeedTwoPlayers =>
      'Servono almeno 2 giocatori, tutti connessi.';

  @override
  String get onlineWaitingForHost =>
      'In attesa che l\'ospitante avvii la partita…';

  @override
  String get onlineLeaveButton => 'Esci';

  @override
  String get onlineLeaveConfirmTitle => 'Uscire dalla partita online?';

  @override
  String get onlineLeaveConfirmBody =>
      'In una partita già iniziata il tuo posto resterà vuoto e la partita aspetterà il tuo ritorno.';

  @override
  String get onlineConnecting => 'Connessione al server…';

  @override
  String get onlineReconnecting => 'Connessione persa, riconnessione…';

  @override
  String get onlineSuspended =>
      'Partita sospesa: un giocatore è assente da troppo tempo.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName sta giocando…';
  }

  @override
  String get onlineDiceOffContinue => 'Gioca';

  @override
  String get onlineErrorUnreachable => 'Server non raggiungibile.';

  @override
  String get onlineErrorRoomNotFound => 'Nessuna stanza con questo codice.';

  @override
  String get onlineErrorRoomFull => 'Questa stanza è piena.';

  @override
  String get onlineErrorGameStarted => 'Questa partita è già iniziata.';

  @override
  String get onlineErrorRateLimited =>
      'Troppi tentativi: riprova tra un istante.';

  @override
  String get onlineErrorBadToken =>
      'Il tuo posto in questa stanza non esiste più.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Aggiorna l\'app per giocare online.';

  @override
  String get onlineErrorGeneric => 'Si è verificato un errore.';
}
