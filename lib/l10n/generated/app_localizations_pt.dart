// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get splashPresents => 'apresenta';

  @override
  String get ownerNameDialogTitle => 'Qual é o teu nome?';

  @override
  String get ownerNameFieldLabel => 'Nome do jogador principal';

  @override
  String get laterButton => 'Mais tarde';

  @override
  String get validateButton => 'Confirmar';

  @override
  String get settingsTooltip => 'Definições';

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
    return 'Jogadores ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Jogador $number';
  }

  @override
  String get unnamedPlayerFallback => 'Jogador';

  @override
  String playerNameFieldLabel(int number) {
    return 'Nome do jogador $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Adicionar';

  @override
  String get removePlayerButton => 'Remover';

  @override
  String get botDifficultyTitle => 'Dificuldade dos bots';

  @override
  String get aiDifficultyCautious => 'Prudente';

  @override
  String get aiDifficultyBalanced => 'Equilibrado';

  @override
  String get aiDifficultyAggressive => 'Agressivo';

  @override
  String get startGameButton => 'Começar jogo';

  @override
  String get newGameSectionLabel => 'Nova run...';

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
  String get scoreChartEmpty =>
      'Aucun tour terminé pour l\'instant : il n\'y a encore rien à tracer.';

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
    return 'Runs interrompidas ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Runs terminadas ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Ainda não há jogos em pausa.';

  @override
  String get noFinishedRunsMessage => 'Ainda não há runs terminadas.';

  @override
  String get deleteGameConfirmTitle => 'Eliminar este jogo?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'O jogo «$alias» será eliminado definitivamente.';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get scoreGridLabel => 'Tabela de pontuações';

  @override
  String get finalRoundBanner => 'Última ronda: um jogador atingiu 10000!';

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
      'Retomar esta mão já ultrapassaria 10000: não é possível parar.';

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
  String get stopButton => 'Parar';

  @override
  String get bustedTitle => 'Rebentou!';

  @override
  String get bustExceedsTarget => 'Esta jogada ultrapassaria 10000.';

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
  String get failureBelowMinimum => 'Pontuação insuficiente para parar.';

  @override
  String get failureEndsIn50 =>
      'Não podes parar com uma pontuação que termine em 50.';

  @override
  String get failureMustContinueHotDice => 'Tens de relançar.';

  @override
  String get failureNotRolledYet =>
      'Tens de lançar os dados antes de poderes parar.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Parar agora tornaria impossível chegar exatamente a 10000.';

  @override
  String get settingsMainPlayerTitle => 'Jogador principal';

  @override
  String get settingsYourNameLabel => 'O teu nome (dono do aparelho)';

  @override
  String get settingsDelaysTitle => 'Temporizações';

  @override
  String get settingsDelaysDescription =>
      'Atraso antes de uma ação automática se ativar sozinha. 0 para desativar.';

  @override
  String get settingsAiDelayLabel => 'Mensagens da IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Ações automáticas do jogador humano (ms)';

  @override
  String get settingsDiceTitle => 'Dados';

  @override
  String get settingsDiceUniform => 'Uniforme';

  @override
  String get settingsDiceVaried => 'Variado';

  @override
  String get settingsSoundsTitle => 'Som';

  @override
  String get settingsMusicLabel => 'Música de fundo';

  @override
  String get settingsSoundEffectsLabel => 'Efeitos sonoros';

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
  String get settingsPausedGamesTitle => 'Jogos em pausa';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmar antes de eliminar um jogo';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSystemOption => 'Idioma do telemóvel';

  @override
  String get diceOffTitle => 'Quem começa?';

  @override
  String get diceOffInstructions =>
      'Cada um lança um dado: a pontuação mais baixa começa o jogo.';

  @override
  String diceOffTieBreak(String names) {
    return 'Empate: $names relançam.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName lança o dado';
  }

  @override
  String get diceOffRollButton => 'Lançar o dado';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName começa o jogo!';
  }

  @override
  String get gameOverTitle => 'Fim do jogo';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vence!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Passa o aparelho a';

  @override
  String get readyButton => 'Pronto';

  @override
  String get notEnteredLabel => '(não entrou)';

  @override
  String get opportunityTooltip =>
      'A 200 pontos de riscar o jogador logo acima!';

  @override
  String get dangerTooltip =>
      'Perigo: o jogador logo abaixo está a apenas 200 pontos, risco de te riscar';

  @override
  String get tiretTooltip => 'Traço: um segundo rebentamento risca a pontuação';

  @override
  String get previousScoreHadTiretTooltip =>
      'A pontuação anterior tinha um traço';

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
