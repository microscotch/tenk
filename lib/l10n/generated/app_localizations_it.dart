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
  String get failureMustContinueFinalRound =>
      'Non puoi fermarti: l\'ultimo giro richiede di raggiungere esattamente 10000.';

  @override
  String get failureNotRolledYet =>
      'Devi lanciare i dadi prima di poterti fermare.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Fermarti ora renderebbe impossibile raggiungere esattamente 10000.';

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
  String get tutorialTitle => 'Tutorial';

  @override
  String get tutorialSkip => 'Salta';

  @override
  String get tutorialNext => 'Avanti';

  @override
  String get tutorialRoll => 'Lancia i dadi';

  @override
  String get tutorialKeep => 'Tieni';

  @override
  String get tutorialFinish => 'Inizia a giocare';

  @override
  String get tutorialReplayButton => 'Rivedi il tutorial';

  @override
  String get tutorialStep0 =>
      'Benvenuto in Le 10000! L\'obiettivo: raggiungere esattamente 10.000 punti. Giocheremo un turno insieme; nulla di ciò che fai qui viene salvato.';

  @override
  String get tutorialStep1 =>
      'Al tuo turno lanci 5 dadi. Tocca «Lancia i dadi».';

  @override
  String get tutorialStep2 =>
      'Qui valgono solo l\'1 (100 punti) e il 5 (50 punti). L\'1 è obbligatorio; il 5 si potrebbe mettere da parte, ma teniamolo. Tocca «Tieni».';

  @override
  String get tutorialStep3 =>
      'La mano corrente vale 150 punti e restano 3 dadi da rilanciare. Per entrare in partita servono almeno 500 punti: rilanciamo.';

  @override
  String get tutorialStep4 =>
      'Tre dadi uguali: tre 3 valgono 300 punti. Tienili.';

  @override
  String get tutorialStep5 =>
      'Tutti i dadi hanno fatto punti: dadi bollenti! Bisogna rilanciare tutti e 5 i dadi, senza potersi fermare. La mano corrente conserva i suoi 450 punti.';

  @override
  String get tutorialStep6 =>
      'Due 1 e un 5: 250 in più, cioè 700. Tenere il 5 conviene: fermarsi a 650 sarebbe vietato (mai un totale che finisce per 50).';

  @override
  String get tutorialStep7 =>
      '700 punti: più di 500 e niente 50 alla fine. Puoi fermarti e incassarli. Tocca «Fermarsi».';

  @override
  String get tutorialStep8 =>
      '700 punti incassati! Vediamo ora cosa succede quando i dadi non valgono nulla: lancia.';

  @override
  String get tutorialStep9 =>
      'Nessun dado fa punti: uno sballo! Il turno è perso e un trattino segna la tua riga di punteggio; un secondo sballo la cancellerebbe. Il primo a raggiungere esattamente 10.000 fa scattare un giro finale per gli altri. Le regole complete sono nel menu. Buon divertimento!';

  @override
  String get rulesGoalTitle => 'Scopo del gioco';

  @override
  String get rulesGoalBody =>
      'Raggiungere esattamente 10.000 punti. Superarli non conta.';

  @override
  String get rulesTurnTitle => 'Come si gioca un turno';

  @override
  String get rulesTurnBody =>
      'Lanci 5 dadi, metti da parte almeno un dado che vale punti, poi rilanci i restanti oppure ti fermi e incassi. Se un lancio non vale nulla, è uno sballo: perdi tutto ciò che avevi accumulato in questo turno.';

  @override
  String get rulesScoringTitle => 'Cosa fa punti';

  @override
  String get rulesScoringBody =>
      '• Un 1 singolo: 100 punti. Un 5 singolo: 50 punti. Gli altri valori singoli (2, 3, 4, 6) non valgono nulla.\n• Un tris: il valore del dado × 100 (tre 6 valgono 600), tranne tre 1, che valgono 1000.\n• Un poker: 1000 punti in più del tris corrispondente (quattro 6 valgono 1600, quattro 1 valgono 2000).\n• Cinque dadi uguali valgono il valore del dado × 1000. Cinque 1 danno subito 10.000 punti: la vittoria immediata.\n• Una scala di 5 dadi consecutivi (1-2-3-4-5 o 2-3-4-5-6) vale 500 punti.';

  @override
  String get rulesBustTitle => 'Sballo e barrato';

  @override
  String get rulesBustBody =>
      'Uno sballo mette un trattino sulla tua riga di punteggio attuale. Se ne aveva già uno, la riga viene cancellata e torni al punteggio precedente. Se raggiungi lo stesso totale di un altro giocatore, è lui a essere barrato.';

  @override
  String get rulesEntryTitle => 'Fermarsi';

  @override
  String get rulesEntryBody =>
      '• Servono almeno 500 punti per entrare in partita, poi almeno 200 per turno.\n• Non puoi mai fermarti su un totale di turno che finisce per 50 (250, 450…).\n• Se tutti i tuoi dadi valgono punti («dadi bollenti»), devi rilanciare tutti e 5.';

  @override
  String get rulesExtensionTitle => 'La regola dell\'estensione';

  @override
  String get rulesExtensionBody =>
      'Una volta incassato un tris o un poker, ogni dado singolo dello stesso valore più avanti nel turno vale 100, compreso un 5. Svanisce con i dadi bollenti.';

  @override
  String get rulesInheritTitle => 'Ereditare i dadi del giocatore precedente';

  @override
  String get rulesInheritBody =>
      'Se ti fermi con dei dadi non ancora lanciati, il giocatore successivo può riprendere quei dadi e il tuo punteggio come base, oppure ripartire con 5 dadi nuovi. Dopo uno sballo riparte sempre con 5 dadi nuovi.';

  @override
  String get rulesVictoryTitle => '10.000 esatti e giro finale';

  @override
  String get rulesVictoryBody =>
      'Non appena un lancio permette di raggiungere esattamente 10.000, la presa è automatica e il turno si ferma. Gli altri giocatori hanno allora un ultimo turno per eguagliare quel punteggio: in esso nessuno può fermarsi sotto i 10.000, bisogna eguagliarlo o fare uno sballo. Se anche un altro giocatore arriva a 10.000 esatti, barra il primo e un nuovo giro finale ricomincia attorno a lui.\nCaso particolare: una mano piena che cade esattamente su 10.000 è uno sballo, perché obbliga a rilanciare. Vince solo la cinquina d\'assi.';

  @override
  String get onlinePlayButton => 'Gioca online';

  @override
  String get onlineResumeButton => 'Riprendi la partita online';

  @override
  String get onlineTitle => 'Partita online';

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
  String get onlineShareButton => 'Condividi il codice';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Unisciti alla mia partita online di Le 10000! Codice della stanza: $code\n$link';
  }

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

  @override
  String get myProfileTitle => 'Il mio profilo';

  @override
  String get myProfileWelcomeTitle => 'Benvenuto!';

  @override
  String get myProfileWelcomeMessage =>
      'Crea il tuo profilo: il tuo nome, un soprannome se vuoi, e la mano con cui giochi. Online gli altri giocatori vedranno il tuo soprannome, o il tuo nome se non ne hai uno.';

  @override
  String get myProfileExistingPrompt =>
      'Sei già nell\'elenco dei giocatori? Tocca il tuo nome.';

  @override
  String get myProfileCreateButton => 'Crea il mio profilo';

  @override
  String get myProfileEditButton => 'Modifica il mio profilo';

  @override
  String get myProfileBadge => 'Io';

  @override
  String onlinePlayingAs(String name) {
    return 'Giochi come «$name»';
  }

  @override
  String get onlineNameInvalidError =>
      'Online il tuo soprannome (o il tuo nome) deve avere al massimo 20 caratteri, senza caratteri invisibili.';

  @override
  String get settingsDiceSoundLabel => 'Suono dei dadi';

  @override
  String get settingsDiceSoundRealistic => 'Realistico';

  @override
  String get settingsDiceSoundSynthetic => 'Sintetico';

  @override
  String get homeChipsHint => 'Tieni premuta una fiche per vederne il nome.';

  @override
  String get emoteThoughtful => 'Pensieroso';

  @override
  String get emoteMocking => 'Morto dal ridere';

  @override
  String get emoteDevastated => 'Distrutto';

  @override
  String get emoteJoyful => 'Abbraccio';

  @override
  String get emotePhraseCoincidence => 'Che coincidenza...';

  @override
  String get emotePhraseStickyFive => 'Il cinque non si stacca!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Mano piena, mano vana!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Un 1000 non si riprende mai!';

  @override
  String get emotePhraseNoWay => 'Semplicemente impossibile!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Ciao!';

  @override
  String get emotePhraseYes => 'Sì!';

  @override
  String get emotePhraseTooGreedy => 'Troppo ingordo!';

  @override
  String get emotePhraseTooLucky => 'Un po\' troppo fortunato...';

  @override
  String get emotePhraseDryTenThousand => 'Dritto ai 10000';

  @override
  String get emotePhraseLucky => 'Che fortunello!';

  @override
  String get emotePhraseGoodLuck => 'Buona fortuna!';

  @override
  String get emotePhraseThanks => 'Grazie';

  @override
  String get emotePhraseSorryMustGo => 'Scusate, ma devo andare';

  @override
  String get gameHistoryBar => 'Cronologia';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'È disponibile una nuova versione ($version, build $build).';
  }

  @override
  String get updateNowButton => 'Aggiorna';

  @override
  String get updateLaterButton => 'Più tardi';
}
