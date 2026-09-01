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
  String get pausedGamesSectionLabel => 'Runs interrompus';

  @override
  String get finishedRunsSectionLabel => 'Runs terminés';

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
  String get leaveGameTooltip => 'Quitter la partie';

  @override
  String get scoreGridLabel => 'Grille des scores';

  @override
  String get finalRoundBanner => 'Tour final : un joueur a atteint 10000 !';

  @override
  String turnScoreLabel(int score) {
    return 'Score du tour : $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minimum requis : $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Dés gardés ce tour';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount dés',
      one: '$diceCount dé',
    );
    return '$playerName hérite de $_temp0 du tour précédent.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Score en cours : $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return 'Continuer avec $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Reprendre cette main dépasserait déjà 10000 : impossible de banquer.';

  @override
  String get restartWithFreshDiceButton => 'Recommencer avec 5 dés neufs';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dés',
      one: '$count dé',
    );
    return 'Reprendre avec $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Repartir avec 5 dés neufs';

  @override
  String get keepDiceButton => 'Garder les dés';

  @override
  String get reRollFullHandButton => 'Relancer (main pleine)';

  @override
  String get stopButton => 'S\'arrêter';

  @override
  String get rollDiceButton => 'Lancer les dés';

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
  String get continueButton => 'Continuer';

  @override
  String thisRollScoreLabel(int score) {
    return 'Score de ce lancer : $score';
  }

  @override
  String get howManyFivesToKeep => 'Combien de 5 garder ?';

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
}
