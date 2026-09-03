// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Romanian Moldavian Moldovan (`ro`).
class AppLocalizationsRo extends AppLocalizations {
  AppLocalizationsRo([String locale = 'ro']) : super(locale);

  @override
  String get splashPresents => 'prezintă';

  @override
  String get ownerNameDialogTitle => 'Cum te numești?';

  @override
  String get ownerNameFieldLabel => 'Numele jucătorului principal';

  @override
  String get laterButton => 'Mai târziu';

  @override
  String get validateButton => 'Confirmă';

  @override
  String get settingsTooltip => 'Setări';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String playersCountTitle(int count) {
    return 'Jucători ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Jucătorul $number';
  }

  @override
  String get unnamedPlayerFallback => 'Jucător';

  @override
  String playerNameFieldLabel(int number) {
    return 'Numele jucătorului $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Adaugă';

  @override
  String get removePlayerButton => 'Elimină';

  @override
  String get botDifficultyTitle => 'Dificultatea boților';

  @override
  String get aiDifficultyCautious => 'Prudent';

  @override
  String get aiDifficultyBalanced => 'Echilibrat';

  @override
  String get aiDifficultyAggressive => 'Agresiv';

  @override
  String get startGameButton => 'Începe jocul';

  @override
  String get newGameSectionLabel => 'Run nou...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Run-uri întrerupte ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Run-uri terminate ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Niciun joc în pauză momentan.';

  @override
  String get noFinishedRunsMessage => 'Niciun run terminat momentan.';

  @override
  String get deleteGameConfirmTitle => 'Ștergi acest joc?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Jocul „$alias” va fi șters definitiv.';
  }

  @override
  String get cancelButton => 'Anulează';

  @override
  String get deleteButton => 'Șterge';

  @override
  String get resumeLastGameDialogTitle => 'Reprendre la partie ?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Une partie « $alias » est en cours. Voulez-vous la reprendre ?';
  }

  @override
  String get resumeGameButton => 'Reprendre';

  @override
  String get leaveGameTooltip => 'Părăsește jocul';

  @override
  String get scoreGridLabel => 'Grilă de scoruri';

  @override
  String get finalRoundBanner => 'Ultima rundă: un jucător a atins 10000!';

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
      'Reluarea acestei mâini ar depăși deja 10000: nu te poți opri.';

  @override
  String get declineInheritedHandButton => 'Refuser';

  @override
  String get aiRestartWithFreshDiceLabel => 'Reîncepe cu 5 zaruri noi';

  @override
  String get keepDiceButton => 'Păstrează zarurile';

  @override
  String get stopButton => 'Oprește-te';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return '$_temp0 de aruncat';
  }

  @override
  String get bustedTitle => 'Ai ars!';

  @override
  String get bustExceedsTarget => 'Această aruncare ar depăși 10000.';

  @override
  String get fullHandMustReroll =>
      'Zaruri fierbinți: trebuie să arunci din nou!';

  @override
  String get failureBelowMinimum => 'Scor insuficient pentru a te opri.';

  @override
  String get failureEndsIn50 =>
      'Nu te poți opri la un scor care se termină în 50.';

  @override
  String get failureMustContinueHotDice => 'Trebuie să arunci din nou.';

  @override
  String get failureNotRolledYet =>
      'Trebuie să arunci zarurile înainte de a te putea opri.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Oprirea acum ar face imposibilă atingerea exactă a 10000.';

  @override
  String get settingsMainPlayerTitle => 'Jucătorul principal';

  @override
  String get settingsYourNameLabel =>
      'Numele tău (proprietarul dispozitivului)';

  @override
  String get settingsDelaysTitle => 'Temporizări';

  @override
  String get settingsDelaysDescription =>
      'Întârziere înainte ca o acțiune automată să se declanșeze singură. 0 pentru a dezactiva.';

  @override
  String get settingsAiDelayLabel => 'Mesaje IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Acțiuni automate ale jucătorului uman (ms)';

  @override
  String get settingsDiceTitle => 'Zaruri';

  @override
  String get settingsDiceUniform => 'Uniformă';

  @override
  String get settingsDiceVaried => 'Variată';

  @override
  String get settingsSoundsTitle => 'Sunet';

  @override
  String get settingsMusicLabel => 'Muzică de fundal';

  @override
  String get settingsSoundEffectsLabel => 'Efecte sonore';

  @override
  String get settingsPausedGamesTitle => 'Jocuri în pauză';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmă înainte de a șterge un joc';

  @override
  String get settingsLanguageTitle => 'Limbă';

  @override
  String get settingsLanguageSystemOption => 'Limba telefonului';

  @override
  String get diceOffTitle => 'Cine începe?';

  @override
  String get diceOffInstructions =>
      'Fiecare aruncă un zar: cel mai mic scor începe jocul.';

  @override
  String diceOffTieBreak(String names) {
    return 'Egalitate: $names aruncă din nou.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName aruncă zarul';
  }

  @override
  String get diceOffRollButton => 'Aruncă zarul';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName începe jocul!';
  }

  @override
  String get gameOverTitle => 'Sfârșitul jocului';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName câștigă!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Joc nou';

  @override
  String get passDeviceInstruction => 'Dă dispozitivul mai departe lui';

  @override
  String get readyButton => 'Gata';

  @override
  String get notEnteredLabel => '(neintrat)';

  @override
  String get opportunityTooltip =>
      'La 200 de puncte distanță de a-l anula pe jucătorul de deasupra!';

  @override
  String get dangerTooltip =>
      'Pericol: jucătorul de dedesubt este la doar 200 de puncte, risc să te anuleze';

  @override
  String get tiretTooltip => 'Liniuță: un al doilea eșec va anula scorul';

  @override
  String get previousScoreHadTiretTooltip => 'Scorul anterior avea o liniuță';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return 'Probabilitate de a marca cu $_temp0';
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
