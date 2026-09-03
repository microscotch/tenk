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
  String get autoChipLabel => 'AutoRoll';

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
  String get newGameSectionLabel => 'Nuova run...';

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
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Esci dalla partita';

  @override
  String get scoreGridLabel => 'Tabellone dei punteggi';

  @override
  String get finalRoundBanner =>
      'Ultimo giro: un giocatore ha raggiunto 10000!';

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
      'Riprendere questa mano supererebbe già 10000: impossibile fermarsi.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel => 'Riparti con 5 dadi nuovi';

  @override
  String get keepDiceButton => 'Tieni i dadi';

  @override
  String get stopButton => 'Fermati';

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
