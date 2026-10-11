// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get splashPresents => 'présente';

  @override
  String get validateButton => 'Valider';

  @override
  String get settingsTooltip => 'Paramètres';

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
    return 'Joueurs ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Commencer la partie';

  @override
  String get newGameSectionLabel => 'Nouvelle partie';

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
    return 'Runs interrompues ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Runs terminées ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Aucune partie en pause pour l\'instant.';

  @override
  String get noFinishedRunsMessage => 'Aucune run terminée pour l\'instant.';

  @override
  String get gameRunParticipantsSeparator => ' vs ';

  @override
  String get deleteGameConfirmTitle => 'Supprimer cette partie ?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'La partie « $alias » sera définitivement supprimée.';
  }

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

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
  String get scoreGridLabel => 'Grille des scores';

  @override
  String get finalRoundBanner => 'Tour final : un joueur a atteint 10000 !';

  @override
  String get currentRollZoneLabel => 'Piste';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Piste ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Main courante';

  @override
  String get logHotDiceMessage => 'Main pleine !';

  @override
  String rollButtonHotDiceTotal(int total) {
    return 'Main pleine ! → $total';
  }

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
  String logBustMessage(int lost) {
    return '$lost : Craqué !';
  }

  @override
  String logBustTiretMessage(int lost, int score) {
    return '$lost : Craqué ! => $score petit trait';
  }

  @override
  String logBustBarredPrefix(int lost) {
    return '$lost : Craqué ! =>';
  }

  @override
  String logBustBarredReturnMessage(int score) {
    return 'retour à $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Reprendre cette main atteindrait déjà 10000 : impossible de banquer.';

  @override
  String get rollButton => 'Lancer';

  @override
  String get showProbabilitiesSetting => 'Afficher les probabilités';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Affiche sur le bouton \"Lancer\" la chance de marquer au moins un point';

  @override
  String get stopButton => 'S\'arrêter';

  @override
  String get bustedTitle => 'Craqué !';

  @override
  String get bustExceedsTarget => 'Ce lancer ferait dépasser 10000.';

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
  String get failureBelowMinimum => 'Score insuffisant pour s\'arrêter.';

  @override
  String get failureEndsIn50 =>
      'Interdit de s\'arrêter sur un score finissant par 50.';

  @override
  String get failureMustContinueHotDice => 'Vous devez relancer.';

  @override
  String get failureMustContinueFinalRound =>
      'Impossible de s\'arrêter : le tour final exige d\'atteindre 10000 pile.';

  @override
  String get failureNotRolledYet =>
      'Vous devez lancer les dés avant de pouvoir vous arrêter.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'S\'arrêter rendrait la victoire à 10000 inatteignable.';

  @override
  String get settingsDelaysTitle => 'Temporisations';

  @override
  String get settingsDelaysDescription =>
      'Délai avant qu\'une action automatique ne se déclenche seule. 0 pour désactiver.';

  @override
  String get settingsAiDelayLabel => 'Messages IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Actions automatiques du joueur humain (ms)';

  @override
  String get settingsDiceTitle => 'Dés';

  @override
  String get settingsDiceUniform => 'Uniforme';

  @override
  String get settingsDiceVaried => 'Panachée';

  @override
  String get settingsSoundsTitle => 'Sons';

  @override
  String get settingsMusicLabel => 'Musique de fond';

  @override
  String get settingsSoundEffectsLabel => 'Effets sonores';

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
  String get settingsPausedGamesTitle => 'Parties en pause';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmer avant de supprimer une partie';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSystemOption => 'Langue du téléphone';

  @override
  String get reorderPlayersHint =>
      'Glissez un joueur par sa poignée pour changer l\'ordre autour de la table.';

  @override
  String get reorderPlayerHandleLabel => 'Déplacer ce joueur';

  @override
  String get diceOffTitle => 'Qui commence ?';

  @override
  String get diceOffInstructions =>
      'Tout le monde lance son dé en même temps : le plus faible commence. En cas d\'égalité, les ex-aequo relancent.';

  @override
  String diceOffTieBreak(String names) {
    return 'Égalité : $names relancent.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName commence la partie !';
  }

  @override
  String get gameOverTitle => 'Fin de la partie';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName gagne !';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name : $score';
  }

  @override
  String get passDeviceInstruction => 'Passez l\'appareil à';

  @override
  String get readyButton => 'Prêt';

  @override
  String get notEnteredLabel => '(pas entré)';

  @override
  String get opportunityTooltip =>
      'À 200 points de barrer le joueur juste au-dessus !';

  @override
  String get dangerTooltip =>
      'Danger : le joueur juste en dessous n\'est qu\'à 200 points, risque de vous barrer';

  @override
  String get tiretTooltip => 'Tiret : un second craque barrera le score';

  @override
  String get radarTargetsTooltip =>
      'Scores que la main en cours permettrait de barrer';

  @override
  String get radarGapTooltip => 'Écart avec le total de la main en cours';

  @override
  String get previousScoreHadTiretTooltip =>
      'Le score précédent portait un tiret';

  @override
  String get rankFirstTooltip => 'En tête';

  @override
  String get rankSecondTooltip => '2e au score';

  @override
  String get rankThirdTooltip => '3e au score';

  @override
  String get rulesScreenTitle => 'Règles du jeu';

  @override
  String get tutorialTitle => 'Tutoriel';

  @override
  String get tutorialSkip => 'Passer';

  @override
  String get tutorialFinalOutro =>
      'Le bot est barré et doit à son tour tenter les 10 000. Vous connaissez maintenant toutes les règles : bonne partie !';

  @override
  String get tutorialFinalExact =>
      'Un brelan de 4 : 10 000 pile ! La prise est automatique.';

  @override
  String get tutorialFinalNoStop =>
      '100 : 9600. Dans le dernier tour, pas d\'arrêt possible : relancez.';

  @override
  String get tutorialFinalIntro =>
      'Le bot a atteint 10 000 : c\'est le dernier tour. Pour gagner, il faut l\'égaler, ce qui le barre. S\'arrêter avant est interdit.';

  @override
  String get tutorialCollisionOutro =>
      'Le bot est barré et retombe à 1500. Atteindre une ligne, même ancienne, d\'un autre joueur la barre aussi.';

  @override
  String get tutorialCollisionCollide =>
      'Deux as : 200. Vous seriez à 2000, le score du bot, en rouge dans son radar. Arrêtez-vous pour le barrer.';

  @override
  String get tutorialCollisionIntro =>
      'Sur la ligne du bot, le radar montre ses scores que vous pourriez barrer : atteindre le même total le fait reculer.';

  @override
  String get tutorialInheritOutro =>
      'Après un craque, on repart toujours à 5 dés neufs. Une main qui ne pourrait plus être encaissée n\'est jamais proposée.';

  @override
  String get tutorialInheritStop => 'Un as : la main vaut 1100. Arrêtez-vous.';

  @override
  String get tutorialInheritTake =>
      'Le bot s\'est arrêté à 1000 en laissant 2 dés. Reprenez la main : vous partez de ses 1000 points, et les 2 dés se lancent aussitôt (on lance toujours au moins une fois avant de s\'arrêter).';

  @override
  String get tutorialInheritIntro =>
      'Quand un joueur s\'arrête en laissant des dés, le suivant peut les reprendre, avec ses points comme base.';

  @override
  String get tutorialExtensionOutro =>
      'L\'extension vaut pour tout le tour, même pour un 5 (100 au lieu de 50), et s\'efface à la main pleine.';

  @override
  String get tutorialExtensionExtended =>
      'Un 2 seul ne vaut rien… sauf ici : après votre brelan de 2, il vaut 100 (en rouge). La main fait 300 : arrêtez-vous.';

  @override
  String get tutorialExtensionBrelan =>
      'Un brelan de 2 : 200. Relancez les 2 derniers dés.';

  @override
  String get tutorialExtensionIntro =>
      'Après un brelan d\'une valeur, un dé seul de la même valeur, plus tard dans le tour, vaut 100 points.';

  @override
  String get tutorialBustOutro =>
      'Un craque marque la ligne d\'un trait ; un second la barre. À 0, un craque ne coûte rien.';

  @override
  String get tutorialBustBarred =>
      'Second craque : la ligne 1500 est barrée, vous retombez à 500, votre score précédent. Appuyez sur ✓.';

  @override
  String get tutorialBustRollAgain =>
      'Votre ligne porte un trait : un second craque la barrerait. Lancez quand même.';

  @override
  String get tutorialBustTiret =>
      'Craqué ! La main est perdue, et votre ligne de 1500 reçoit un petit trait. Appuyez sur ✓.';

  @override
  String get tutorialBustIntro =>
      'Un lancer qui ne rapporte rien est un craque : la main en cours est perdue. Vous avez 1500 points.';

  @override
  String get tutorialHotDiceOutro =>
      'Retenez : jamais d\'arrêt sur un total qui finit par 50, et une main pleine se relance toujours.';

  @override
  String get tutorialHotDiceStop =>
      '500 : assez pour entrer, et pas de 50 à la fin. Arrêtez-vous.';

  @override
  String get tutorialHotDiceFives =>
      'Deux 5, mais facultatifs : ce sélecteur choisit combien en garder. Avec les deux, 550 finirait en 50 : impossible de s\'arrêter. Choisissez 1.';

  @override
  String get tutorialHotDiceFullHand =>
      'Un brelan de 3 : 300, la main monte à 450. Tous les dés ont servi : main pleine ! Le bouton montre le total que vous auriez ; on relance les 5 dés, sans pouvoir s\'arrêter.';

  @override
  String get tutorialHotDiceKept =>
      'L\'as et le 5 sont gardés : la main vaut 150. Relancez les 3 autres dés.';

  @override
  String get tutorialHotDiceIntro =>
      'Quand tous les dés rapportent, c\'est la main pleine : on relance les 5. Et un 5 seul est parfois facultatif.';

  @override
  String get tutorialBasicsOutro =>
      '700 points encaissés : vous êtes dans la partie ! Ensuite, chaque tour devra rapporter au moins 200 points.';

  @override
  String get tutorialBasicsBrelan =>
      'Trois 6 : un brelan vaut 100 fois sa valeur, ici 600 (trois as : 1000). La main vaut 700, assez pour entrer : appuyez sur la main pour vous arrêter.';

  @override
  String get tutorialBasicsAce =>
      'Seuls l\'as (100) et le 5 (50) rapportent seuls : l\'as est mis de côté. Pour entrer dans la partie, il faut 500 points en un tour : relancez les 4 autres dés.';

  @override
  String get tutorialBasicsIntro =>
      'Bienvenue dans Le 10000 ! Le but : atteindre exactement 10 000 points. À chaque tour, on lance 5 dés et on met de côté ceux qui rapportent.';

  @override
  String get tutorialLessonFinalRound => 'Le dernier tour';

  @override
  String get tutorialLessonCollision => 'Barrer un joueur';

  @override
  String get tutorialLessonInheritedHand => 'La main héritée';

  @override
  String get tutorialLessonExtension => 'L\'extension';

  @override
  String get tutorialLessonBust => 'Le craque';

  @override
  String get tutorialLessonHotDice => 'La main pleine';

  @override
  String get tutorialLessonBasics => 'Les bases';

  @override
  String get tutorialBotTurn => 'Au tour du bot : il joue seul.';

  @override
  String get tutorialRollPrompt => 'Appuyez sur le bouton de lancer.';

  @override
  String get tutorialWholePath => 'Tout le parcours';

  @override
  String get tutorialLessonsTitle => 'Leçons du tutoriel';

  @override
  String get tutorialNextLesson => 'Leçon suivante';

  @override
  String tutorialLessonCounter(int number, int total, String title) {
    return 'Leçon $number/$total : $title';
  }

  @override
  String get tutorialPlayerName => 'Vous';

  @override
  String get tutorialNext => 'Suivant';

  @override
  String get tutorialFinish => 'Commencer à jouer';

  @override
  String get tutorialReplayButton => 'Leçons du tutoriel';

  @override
  String get rulesGoalTitle => 'But du jeu';

  @override
  String get rulesGoalBody =>
      'Atteindre exactement 10 000 points. Dépasser ne compte pas.';

  @override
  String get rulesTurnTitle => 'Comment se joue un tour';

  @override
  String get rulesTurnBody =>
      'Vous lancez 5 dés, mettez de côté au moins un dé qui rapporte, puis vous relancez les dés restants ou vous vous arrêtez et encaissez. Si un lancer ne rapporte rien, c\'est un craque : vous perdez ce que vous aviez accumulé pendant ce tour.';

  @override
  String get rulesScoringTitle => 'Ce qui rapporte des points';

  @override
  String get rulesScoringBody =>
      '• Un as isolé : 100 points. Un 5 isolé : 50 points. Les autres valeurs isolées (2, 3, 4, 6) ne rapportent rien.\n• Un brelan : la valeur du dé × 100 (trois 6 valent 600), sauf trois as qui valent 1000.\n• Un carré : 1000 points de plus que le brelan correspondant (quatre 6 valent 1600, quatre as 2000).\n• Cinq dés identiques valent la valeur × 1000. Cinq as (la quinte d\'as) valent directement 10 000 points : la victoire immédiate.\n• Une suite de 5 (as-2-3-4-5 ou 2-3-4-5-6) vaut 500 points.';

  @override
  String get rulesBustTitle => 'Craque et barré';

  @override
  String get rulesBustBody =>
      'Un craque met un tiret sur votre ligne de score. S\'il y en avait déjà un, la ligne est barrée et vous retombez à votre score précédent. Si vous atteignez le même total qu\'un autre joueur, c\'est lui qui est barré.';

  @override
  String get rulesEntryTitle => 'Pour s\'arrêter';

  @override
  String get rulesEntryBody =>
      '• Il faut au moins 500 points pour entrer dans la partie, puis au moins 200 par tour.\n• Vous ne pouvez jamais vous arrêter sur un total de tour qui finit par 50 (250, 450…).\n• Si tous vos dés comptent (« dés chauds »), vous devez relancer les 5.';

  @override
  String get rulesExtensionTitle => 'La règle d\'extension';

  @override
  String get rulesExtensionBody =>
      'Une fois un brelan ou un carré encaissé, tout dé isolé de la même valeur plus tard dans le tour vaut 100, y compris un 5. Cela disparaît aux dés chauds.';

  @override
  String get rulesInheritTitle => 'Hériter des dés du joueur précédent';

  @override
  String get rulesInheritBody =>
      'Si vous vous arrêtez avec des dés non lancés, le joueur suivant peut reprendre ces dés et votre score comme base, ou repartir à 5 dés neufs. Après un craque, il repart toujours à 5 dés neufs.';

  @override
  String get rulesVictoryTitle => '10 000 pile et dernier tour';

  @override
  String get rulesVictoryBody =>
      'Dès qu\'un lancer permet d\'atteindre exactement 10 000, la prise est automatique et le tour s\'arrête. Les autres joueurs ont alors un dernier tour pour égaler ce score : on ne peut plus s\'y arrêter sous 10 000, il faut l\'égaler ou craquer. Si un autre joueur atteint aussi 10 000 pile, il barre le premier et un nouveau dernier tour recommence autour de lui.\nCas particulier : une main pleine qui tombe pile sur 10 000 est un craque, car elle oblige à relancer. Seule la quinte d\'as gagne.';

  @override
  String get onlinePlayButton => 'Jouer en ligne';

  @override
  String get onlineResumeButton => 'Reprendre la partie en ligne';

  @override
  String get onlineTitle => 'Partie en ligne';

  @override
  String get onlineCreateButton => 'Créer un salon';

  @override
  String get onlineJoinButton => 'Rejoindre';

  @override
  String get onlineCodeLabel => 'Code du salon';

  @override
  String get onlineOrDivider => 'ou';

  @override
  String get onlineShareHint =>
      'Donnez ce code aux autres joueurs pour qu\'ils vous rejoignent.';

  @override
  String get onlineShareButton => 'Partager le code';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Rejoins ma partie de Le 10000 en ligne ! Code du salon : $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Joueurs ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Hôte';

  @override
  String get onlineDisconnectedBadge => 'Déconnecté';

  @override
  String get onlineNeedTwoPlayers =>
      'Il faut au moins 2 joueurs, tous connectés.';

  @override
  String get onlineWaitingForHost => 'En attente du lancement par l\'hôte…';

  @override
  String get onlineLeaveButton => 'Quitter';

  @override
  String get onlineLeaveConfirmTitle => 'Quitter la partie en ligne ?';

  @override
  String get onlineLeaveConfirmBody =>
      'Dans une partie commencée, votre place restera vide et la partie attendra votre retour.';

  @override
  String get onlineLeaveGameBody =>
      'Vous quittez le salon : un bot jouera à votre place jusqu\'à la fin de la partie.';

  @override
  String get onlineDiceOffWaitingStart => 'En attente du début de la partie';

  @override
  String get logPlayerReplacedByBot =>
      'a quitté la partie : un bot joue à sa place';

  @override
  String get botSeatTooltip => 'Joué par un bot (joueur parti)';

  @override
  String get rematchButton => 'Rejouer';

  @override
  String rematchProposal(String name) {
    return '$name propose une revanche';
  }

  @override
  String get rematchWaiting => 'En attente des autres joueurs…';

  @override
  String rematchSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get rematchAccept => 'Accepter';

  @override
  String get rematchRefuse => 'Refuser';

  @override
  String get rematchExcludedNotice =>
      'Vous avez quitté le salon : pas de revanche pour vous.';

  @override
  String get rematchCancelledNotice =>
      'Pas de revanche : il faut au moins deux joueurs.';

  @override
  String get onlineConnecting => 'Connexion au serveur…';

  @override
  String get onlineReconnecting => 'Connexion perdue, reconnexion…';

  @override
  String get onlineSuspended =>
      'Partie suspendue : un joueur est absent depuis trop longtemps.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName joue…';
  }

  @override
  String get onlineDiceOffContinue => 'Jouer';

  @override
  String get onlineErrorUnreachable => 'Serveur injoignable.';

  @override
  String get onlineErrorRoomNotFound => 'Aucun salon avec ce code.';

  @override
  String get onlineErrorRoomFull => 'Ce salon est complet.';

  @override
  String get onlineErrorGameStarted => 'Cette partie a déjà commencé.';

  @override
  String get onlineErrorRateLimited =>
      'Trop de tentatives : réessayez dans un instant.';

  @override
  String get onlineErrorBadToken => 'Votre place dans ce salon n\'existe plus.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Mettez l\'application à jour pour jouer en ligne.';

  @override
  String get onlineErrorGeneric => 'Une erreur est survenue.';

  @override
  String get myProfileTitle => 'Mon profil';

  @override
  String get myProfileWelcomeTitle => 'Bienvenue !';

  @override
  String get myProfileWelcomeMessage =>
      'Créez votre profil : votre nom, un surnom si vous voulez, et la main avec laquelle vous jouez. En ligne, les autres joueurs verront votre surnom, ou votre nom si vous n\'en avez pas.';

  @override
  String get myProfileExistingPrompt =>
      'Vous êtes déjà dans la liste des joueurs ? Touchez votre nom.';

  @override
  String get myProfileCreateButton => 'Créer mon profil';

  @override
  String get myProfileEditButton => 'Modifier mon profil';

  @override
  String get myProfileBadge => 'Moi';

  @override
  String onlinePlayingAs(String name) {
    return 'Vous jouez sous le nom « $name »';
  }

  @override
  String get onlineNameInvalidError =>
      'En ligne, votre surnom (ou votre nom) doit faire 20 caractères au plus, sans caractère invisible.';

  @override
  String get settingsDiceSoundLabel => 'Bruit des dés';

  @override
  String get settingsDiceSoundRealistic => 'Réaliste';

  @override
  String get settingsDiceSoundSynthetic => 'Synthétique';

  @override
  String get homeChipsHint => 'Appui long sur un jeton : son nom s\'affiche.';

  @override
  String get emoteThoughtful => 'Songeur';

  @override
  String get emoteMocking => 'Mort de rire';

  @override
  String get emoteDevastated => 'Dévasté';

  @override
  String get emoteJoyful => 'Câlin';

  @override
  String get emotePhraseCoincidence => 'Comme de par hasard...';

  @override
  String get emotePhraseStickyFive => 'Cinq qui colle !';

  @override
  String get emotePhraseFullHandEmptyHand => 'Main pleine, main vaine !';

  @override
  String get emotePhraseNeverTakeA1000 => 'On ne reprend jamais sur un 1000 !';

  @override
  String get emotePhraseNoWay => 'Juste pas possible !';

  @override
  String get emotePhraseArgh => 'Aaaaaarg !';

  @override
  String get emotePhraseHello => 'Salut !';

  @override
  String get emotePhraseYes => 'Yes !';

  @override
  String get emotePhraseTooGreedy => 'La gourmandise est un vilain défaut !';

  @override
  String get emotePhraseTooLucky => 'Un peu trop de chance...';

  @override
  String get emotePhraseDryTenThousand => 'En mode 10000 sec';

  @override
  String get emotePhraseLucky => 'Veinard va !';

  @override
  String get emotePhraseGoodLuck => 'Bonne chance !';

  @override
  String get emotePhraseThanks => 'Merci';

  @override
  String get emotePhraseSorryMustGo => 'Désolé mais je dois partir';

  @override
  String get emoteAngry => 'Fâché';

  @override
  String get emoteRelieved => 'Soulagé';

  @override
  String get emotePhraseStrangeChoice => 'Mais quel est ce choix étrange ?';

  @override
  String get emotePhraseAllByFives => 'Tout par les cinq !';

  @override
  String get emotePhraseWithPanache => 'Avec panache !';

  @override
  String get emotePhraseUnfair => 'C\'est vraiment trop injuste';

  @override
  String get emotePhrasePhew => 'Ouf !';

  @override
  String get emotePhraseAtLast => 'Enfin !';

  @override
  String get emotePhraseCloseCall => 'C\'était chaud !';

  @override
  String get emotePhraseWellPlayed => 'Bien joué';

  @override
  String get emotePhraseSorry => 'Désolé';

  @override
  String get gameHistoryBar => 'Historique';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'Une nouvelle version est disponible ($version, build $build).';
  }

  @override
  String get updateNowButton => 'Mettre à jour';

  @override
  String get updateLaterButton => 'Plus tard';
}
