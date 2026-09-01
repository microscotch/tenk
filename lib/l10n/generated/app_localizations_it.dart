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
  String get ownerNameDialogTitle => 'Come ti chiami?';

  @override
  String get ownerNameFieldLabel => 'Nome del giocatore principale';

  @override
  String get laterButton => 'Più tardi';

  @override
  String get validateButton => 'Conferma';

  @override
  String get settingsTooltip => 'Impostazioni';

  @override
  String playersCountTitle(int count) {
    return 'Giocatori ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Giocatore $number';
  }

  @override
  String get unnamedPlayerFallback => 'Giocatore';

  @override
  String playerNameFieldLabel(int number) {
    return 'Nome del giocatore $number';
  }

  @override
  String get autoChipLabel => 'Auto';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Aggiungi';

  @override
  String get removePlayerButton => 'Rimuovi';

  @override
  String get botDifficultyTitle => 'Difficoltà dei bot';

  @override
  String get aiDifficultyCautious => 'Prudente';

  @override
  String get aiDifficultyBalanced => 'Equilibrato';

  @override
  String get aiDifficultyAggressive => 'Aggressivo';

  @override
  String get startGameButton => 'Inizia partita';

  @override
  String get newGameSectionLabel => 'Nuova partita...';

  @override
  String get pausedGamesSectionLabel => 'Partite in pausa';

  @override
  String get noPausedGamesMessage => 'Nessuna partita in pausa per ora.';

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
  String get leaveGameTooltip => 'Esci dalla partita';

  @override
  String get scoreGridLabel => 'Tabellone dei punteggi';

  @override
  String get finalRoundBanner =>
      'Ultimo giro: un giocatore ha raggiunto 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Punti del turno: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minimo richiesto: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Dadi tenuti in questo turno';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount dadi',
      one: '$diceCount dado',
    );
    return '$playerName eredita $_temp0 dal turno precedente.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Punteggio attuale: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return 'Continua con $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Riprendere questa mano supererebbe già 10000: impossibile fermarsi.';

  @override
  String get restartWithFreshDiceButton => 'Ricomincia con 5 dadi nuovi';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return 'Riprendi con $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Riparti con 5 dadi nuovi';

  @override
  String get keepDiceButton => 'Tieni i dadi';

  @override
  String get reRollFullHandButton => 'Rilancia (dadi bollenti)';

  @override
  String get stopButton => 'Fermati';

  @override
  String get rollDiceButton => 'Lancia i dadi';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return '$_temp0 da lanciare';
  }

  @override
  String get bustedTitle => 'Hai sballato!';

  @override
  String get bustExceedsTarget => 'Questo lancio supererebbe 10000.';

  @override
  String get continueButton => 'Continua';

  @override
  String thisRollScoreLabel(int score) {
    return 'Punti di questo lancio: $score';
  }

  @override
  String get howManyFivesToKeep => 'Quanti 5 vuoi tenere?';

  @override
  String get fullHandMustReroll => 'Dadi bollenti: devi rilanciare!';

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
  String get settingsPausedGamesTitle => 'Partite in pausa';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Conferma prima di eliminare una partita';

  @override
  String get settingsLanguageTitle => 'Lingua';

  @override
  String get settingsLanguageSystemOption => 'Lingua del telefono';

  @override
  String get diceOffTitle => 'Chi inizia?';

  @override
  String get diceOffInstructions =>
      'Ognuno lancia un dado: il punteggio più basso inizia la partita.';

  @override
  String diceOffTieBreak(String names) {
    return 'Parità: $names rilanciano.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName lancia il dado';
  }

  @override
  String get diceOffRollButton => 'Lancia il dado';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName inizia la partita!';
  }

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
  String get newGameButton => 'Nuova partita';

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
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dadi',
      one: '$count dado',
    );
    return 'Probabilità di segnare con $_temp0';
  }
}
