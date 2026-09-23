// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get splashPresents => 'präsentiert';

  @override
  String get ownerNameDialogTitle => 'Wie heißt du?';

  @override
  String get ownerNameFieldLabel => 'Name des Hauptspielers';

  @override
  String get laterButton => 'Später';

  @override
  String get validateButton => 'Bestätigen';

  @override
  String get settingsTooltip => 'Einstellungen';

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
  String playersCountTitle(int count) {
    return 'Spieler ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Spieler $number';
  }

  @override
  String get unnamedPlayerFallback => 'Spieler';

  @override
  String playerNameFieldLabel(int number) {
    return 'Name von Spieler $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'KI';

  @override
  String get addPlayerButton => 'Hinzufügen';

  @override
  String get removePlayerButton => 'Entfernen';

  @override
  String get botDifficultyTitle => 'Bot-Schwierigkeit';

  @override
  String get aiDifficultyCautious => 'Vorsichtig';

  @override
  String get aiDifficultyBalanced => 'Ausgewogen';

  @override
  String get aiDifficultyAggressive => 'Aggressiv';

  @override
  String get startGameButton => 'Spiel starten';

  @override
  String get newGameSectionLabel => 'Neuer Run...';

  @override
  String get resumeGamesButton => 'Reprise de parties';

  @override
  String get managePlayersButton => 'Gestion des joueurs';

  @override
  String get finishedGamesButton => 'Dernières parties terminées';

  @override
  String get statisticsButton => 'Statistiques';

  @override
  String playersScreenTitle(int count) {
    return 'Joueurs ($count)';
  }

  @override
  String get addPlayerTooltip => 'Ajouter un joueur';

  @override
  String get noPlayersMessage => 'Aucun joueur enregistré pour l\'instant.';

  @override
  String get newPlayerTitle => 'Nouveau joueur';

  @override
  String get editPlayerTitle => 'Modifier le joueur';

  @override
  String get playerNameLabel => 'Nom';

  @override
  String get playerNicknameLabel => 'Surnom (facultatif)';

  @override
  String get playerNameRequiredError => 'Le nom est obligatoire.';

  @override
  String get playerNameTakenError =>
      'Ce nom est déjà utilisé par un autre joueur.';

  @override
  String get deletePlayerConfirmTitle => 'Supprimer ce joueur ?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'La fiche de « $name » et ses statistiques seront définitivement supprimées. Les parties déjà jouées, elles, sont conservées.';
  }

  @override
  String get statsSectionTime => 'Temps de jeu';

  @override
  String get statsSectionGames => 'Parties';

  @override
  String get statsSectionFigures => 'Figures';

  @override
  String get statsSectionRolls => 'Tours et lancers';

  @override
  String get statsTurns => 'Tours joués';

  @override
  String get statsRolls => 'Lancers';

  @override
  String get statsRollsPerTurn => 'Lancers par tour';

  @override
  String get statsSectionMisc => 'Faits d\'armes';

  @override
  String get statsTotalTime => 'Total';

  @override
  String get statsAverageTime => 'Moyenne par partie';

  @override
  String get statsShortestTime => 'La plus courte';

  @override
  String get statsLongestTime => 'La plus longue';

  @override
  String get statsGamesPlayed => 'Jouées';

  @override
  String get statsGamesWon => 'Gagnées';

  @override
  String get statsGamesLost => 'Perdues';

  @override
  String get statsLoneAces => 'As isolés gardés';

  @override
  String get statsLoneFives => '5 isolés gardés';

  @override
  String get statsBrelans => 'Brelans';

  @override
  String get statsCarres => 'Carrés';

  @override
  String get statsQuintes => 'Quintes';

  @override
  String get statsSuites => 'Suites';

  @override
  String get statsSmallSuites => 'dont petites';

  @override
  String get statsBigSuites => 'dont grandes';

  @override
  String get statsAceQuints => 'Quintes d\'as';

  @override
  String get statsAceQuintsWon => 'dont gagnantes';

  @override
  String get statsBestTurn => 'Meilleur tour';

  @override
  String get statsHotDiceRun => 'Mains pleines d\'affilée';

  @override
  String get statsBusts => 'Craquages';

  @override
  String get statsLongestBustStreak => 'dont série la plus longue';

  @override
  String get statsSelfBars => 'Auto-barrés';

  @override
  String get statsBarsInflicted => 'Barrés infligés';

  @override
  String get scoreChartTitle => 'Évolution des scores';

  @override
  String get gameStatsTitle => 'Statistiques de la partie';

  @override
  String get gameStatsGameSection => 'Partie';

  @override
  String get gameStatsFiguresSection => 'Figures de la partie';

  @override
  String get gameStatsDuration => 'Durée de jeu';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns tours',
      one: '$turns tour',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts craques',
      one: '$busts craque',
    );
    return '$_temp0 · meilleur $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games parties',
      one: '$games partie',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won gagnées',
      one: '$won gagnée',
    );
    return '$_temp0 · $_temp1 · meilleur $best';
  }

  @override
  String get scoreChartEmpty =>
      'Aucun tour terminé pour l\'instant : il n\'y a encore rien à tracer.';

  @override
  String get replayUnavailable =>
      'Cette partie ne peut pas être rejouée : son journal est incomplet.';

  @override
  String get replayPlay => 'Lecture';

  @override
  String get replayPause => 'Pause';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Tour $turn';
  }

  @override
  String get scoreChartXAxis => 'Tours joués';

  @override
  String get statsBreakdownRow => 'dont';

  @override
  String get statsRecordsTitle => 'Records';

  @override
  String get statsNoRecordYet => 'Aucun record pour l\'instant.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Choisir des joueurs';

  @override
  String get addHumanTooltip => 'Ajouter un joueur';

  @override
  String get addBotTooltip => 'Ajouter un bot';

  @override
  String get createPlayerButton => 'Nouveau joueur';

  @override
  String get noPlayersToPickMessage =>
      'Aucun joueur en base. Créez-en un pour commencer.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Retirer de la partie';

  @override
  String get notEnoughPlayersMessage => 'Il faut au moins deux joueurs.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count parties jouées',
      one: '$count partie jouée',
      zero: 'Aucune partie jouée',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Unterbrochene Runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Beendete Runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Noch keine pausierten Spiele.';

  @override
  String get noFinishedRunsMessage => 'Noch keine beendeten Runs.';

  @override
  String get gameRunParticipantsSeparator => ' vs ';

  @override
  String get deleteGameConfirmTitle => 'Dieses Spiel löschen?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Das Spiel „$alias“ wird endgültig gelöscht.';
  }

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get gameOverReplayButton => 'Revoir la partie';

  @override
  String get scoreGridLabel => 'Punktetabelle';

  @override
  String get finalRoundBanner =>
      'Letzte Runde: Ein Spieler hat 10000 erreicht!';

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
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return '$kept : $gain, $_temp0 => $total pts';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept : $gain, main pleine => $total pts';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score pts sont pris => $total pts';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score pts sont repris';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Craqué ! => $score petit trait';
  }

  @override
  String get logBustBarredPrefix => 'Craqué ! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'retour à $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Diese Hand zu übernehmen würde bereits 10000 überschreiten: Einlösen nicht möglich.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get rollButton => 'Lancer';

  @override
  String get showProbabilitiesSetting => 'Afficher les probabilités';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Affiche sur le bouton \"Lancer\" la chance de marquer au moins un point';

  @override
  String get stopButton => 'Aufhören';

  @override
  String get bustedTitle => 'Verloren!';

  @override
  String get bustExceedsTarget => 'Dieser Wurf würde 10000 überschreiten.';

  @override
  String get bustFullHandAtTarget =>
      'Main pleine à 10000 : impossible de s\'arrêter, et tout relancer dépasserait.';

  @override
  String get bustContinueButton => 'Continuer';

  @override
  String get inheritedHandDialogTitle => 'Reprendre ?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Reprendre la main';

  @override
  String get newHandButton => 'Nouvelle main';

  @override
  String get failureBelowMinimum => 'Punktzahl zu niedrig, um aufzuhören.';

  @override
  String get failureEndsIn50 =>
      'Du darfst nicht bei einer Punktzahl aufhören, die auf 50 endet.';

  @override
  String get failureMustContinueHotDice => 'Du musst erneut würfeln.';

  @override
  String get failureNotRolledYet =>
      'Du musst würfeln, bevor du aufhören kannst.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Jetzt aufzuhören würde es unmöglich machen, genau 10000 zu erreichen.';

  @override
  String get settingsMainPlayerTitle => 'Hauptspieler';

  @override
  String get settingsYourNameLabel => 'Dein Name (Gerätebesitzer)';

  @override
  String get settingsDelaysTitle => 'Verzögerungen';

  @override
  String get settingsDelaysDescription =>
      'Verzögerung, bevor eine automatische Aktion von selbst ausgelöst wird. 0 zum Deaktivieren.';

  @override
  String get settingsAiDelayLabel => 'KI-Nachrichten (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatische Aktionen des menschlichen Spielers (ms)';

  @override
  String get settingsDiceTitle => 'Würfel';

  @override
  String get settingsDiceUniform => 'Einheitlich';

  @override
  String get settingsDiceVaried => 'Bunt gemischt';

  @override
  String get settingsSoundsTitle => 'Sound';

  @override
  String get settingsMusicLabel => 'Hintergrundmusik';

  @override
  String get settingsSoundEffectsLabel => 'Soundeffekte';

  @override
  String get settingsHandednessLabel => 'Disposition des boutons';

  @override
  String get settingsHandednessRight => 'Droitier';

  @override
  String get settingsHandednessLeft => 'Gaucher';

  @override
  String get settingsControlsTitle => 'Contrôles';

  @override
  String get settingsShakeToRollLabel => 'Secouer pour lancer les dés';

  @override
  String get settingsPausedGamesTitle => 'Pausierte Spiele';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Vor dem Löschen eines Spiels bestätigen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSystemOption => 'Telefonsprache';

  @override
  String get reorderPlayersHint =>
      'Glissez un joueur par sa poignée pour changer l\'ordre autour de la table.';

  @override
  String get reorderPlayerHandleLabel => 'Déplacer ce joueur';

  @override
  String get diceOffTitle => 'Wer beginnt?';

  @override
  String get diceOffInstructions =>
      'Jeder würfelt einmal: Die niedrigste Punktzahl beginnt das Spiel.';

  @override
  String diceOffTieBreak(String names) {
    return 'Unentschieden: $names würfeln erneut.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName beginnt das Spiel!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Ordre de jeu';

  @override
  String get diceOffReversedNote =>
      'Duel entre voisins remporté par le second : la partie tourne à rebours.';

  @override
  String get gameOverTitle => 'Spielende';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName gewinnt!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Gib das Gerät weiter an';

  @override
  String get readyButton => 'Bereit';

  @override
  String get notEnteredLabel => '(noch nicht eingestiegen)';

  @override
  String get opportunityTooltip =>
      'Nur 200 Punkte davon entfernt, den Spieler direkt darüber zu streichen!';

  @override
  String get dangerTooltip =>
      'Gefahr: Der Spieler direkt darunter ist nur 200 Punkte entfernt und könnte dich streichen';

  @override
  String get tiretTooltip =>
      'Strich: Ein zweiter Fehlwurf streicht die Punktzahl';

  @override
  String get previousScoreHadTiretTooltip =>
      'Die vorige Punktzahl trug einen Strich';

  @override
  String get rankFirstTooltip => 'En tête';

  @override
  String get rankSecondTooltip => '2e au score';

  @override
  String get rankThirdTooltip => '3e au score';

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
