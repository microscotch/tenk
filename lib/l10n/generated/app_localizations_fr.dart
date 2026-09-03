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
  String get ownerNameDialogTitle => 'Votre nom ?';

  @override
  String get ownerNameFieldLabel => 'Nom du joueur principal';

  @override
  String get laterButton => 'Plus tard';

  @override
  String get validateButton => 'Valider';

  @override
  String get settingsTooltip => 'Réglages';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String playersCountTitle(int count) {
    return 'Joueurs ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Joueur $number';
  }

  @override
  String get unnamedPlayerFallback => 'Joueur';

  @override
  String playerNameFieldLabel(int number) {
    return 'Nom du joueur $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Ajouter';

  @override
  String get removePlayerButton => 'Retirer';

  @override
  String get botDifficultyTitle => 'Difficulté des bots';

  @override
  String get aiDifficultyCautious => 'Prudent';

  @override
  String get aiDifficultyBalanced => 'Équilibré';

  @override
  String get aiDifficultyAggressive => 'Agressif';

  @override
  String get startGameButton => 'Commencer la partie';

  @override
  String get newGameSectionLabel => 'Nouveau run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Runs interrompus ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Runs terminés ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Aucune partie en pause pour l\'instant.';

  @override
  String get noFinishedRunsMessage => 'Aucun run terminé pour l\'instant.';

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
  String get leaveGameTooltip => 'Quitter la partie';

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
  String get awaitingRollPlaceholder => 'En attente du prochain lancer';

  @override
  String get logHotDiceMessage => 'Main pleine !';

  @override
  String get logScoreCollisionMessage => 'Score barré :';

  @override
  String get inheritedHandExceedsWinning =>
      'Reprendre cette main dépasserait déjà 10000 : impossible de banquer.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel => 'Repartir avec 5 dés neufs';

  @override
  String get keepDiceButton => 'Garder les dés';

  @override
  String get stopButton => 'S\'arrêter';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return '$_temp0 à lancer';
  }

  @override
  String get bustedTitle => 'Craqué !';

  @override
  String get bustExceedsTarget => 'Ce lancer ferait dépasser 10000.';

  @override
  String get fullHandMustReroll => 'Main pleine : vous devez relancer !';

  @override
  String get failureBelowMinimum => 'Score insuffisant pour s\'arrêter.';

  @override
  String get failureEndsIn50 =>
      'Interdit de s\'arrêter sur un score finissant par 50.';

  @override
  String get failureMustContinueHotDice => 'Vous devez relancer.';

  @override
  String get failureNotRolledYet =>
      'Vous devez lancer les dés avant de pouvoir vous arrêter.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'S\'arrêter rendrait la victoire à 10000 inatteignable.';

  @override
  String get settingsMainPlayerTitle => 'Joueur principal';

  @override
  String get settingsYourNameLabel => 'Votre nom (propriétaire de l\'appareil)';

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
  String get settingsPausedGamesTitle => 'Parties en pause';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmer avant de supprimer une partie';

  @override
  String get settingsLanguageTitle => 'Langue';

  @override
  String get settingsLanguageSystemOption => 'Langue du téléphone';

  @override
  String get diceOffTitle => 'Qui commence ?';

  @override
  String get diceOffInstructions =>
      'Chacun lance un dé : le score le plus faible commence la partie.';

  @override
  String diceOffTieBreak(String names) {
    return 'Égalité : $names relancent.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName lance le dé';
  }

  @override
  String get diceOffRollButton => 'Lancer le dé';

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
  String get newGameButton => 'Nouvelle partie';

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
  String get previousScoreHadTiretTooltip =>
      'Le score précédent portait un tiret';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return 'Probabilité de marquer sur $_temp0';
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
