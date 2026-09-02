// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Finnish (`fi`).
class AppLocalizationsFi extends AppLocalizations {
  AppLocalizationsFi([String locale = 'fi']) : super(locale);

  @override
  String get splashPresents => 'esittää';

  @override
  String get ownerNameDialogTitle => 'Mikä on nimesi?';

  @override
  String get ownerNameFieldLabel => 'Pääpelaajan nimi';

  @override
  String get laterButton => 'Myöhemmin';

  @override
  String get validateButton => 'Vahvista';

  @override
  String get settingsTooltip => 'Asetukset';

  @override
  String get helpTooltip => 'Règles du jeu';

  @override
  String playersCountTitle(int count) {
    return 'Pelaajat ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Pelaaja $number';
  }

  @override
  String get unnamedPlayerFallback => 'Pelaaja';

  @override
  String playerNameFieldLabel(int number) {
    return 'Pelaajan $number nimi';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'AI';

  @override
  String get addPlayerButton => 'Lisää';

  @override
  String get removePlayerButton => 'Poista';

  @override
  String get botDifficultyTitle => 'Bottien vaikeustaso';

  @override
  String get aiDifficultyCautious => 'Varovainen';

  @override
  String get aiDifficultyBalanced => 'Tasapainoinen';

  @override
  String get aiDifficultyAggressive => 'Aggressiivinen';

  @override
  String get startGameButton => 'Aloita peli';

  @override
  String get newGameSectionLabel => 'Uusi run...';

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Keskeytyneet runit ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Päättyneet runit ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Ei vielä tauolla olevia pelejä.';

  @override
  String get noFinishedRunsMessage => 'Ei vielä päättyneitä runeja.';

  @override
  String get deleteGameConfirmTitle => 'Poistetaanko tämä peli?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Peli ”$alias” poistetaan pysyvästi.';
  }

  @override
  String get cancelButton => 'Peruuta';

  @override
  String get deleteButton => 'Poista';

  @override
  String get leaveGameTooltip => 'Poistu pelistä';

  @override
  String get scoreGridLabel => 'Pistetaulukko';

  @override
  String get finalRoundBanner =>
      'Viimeinen kierros: pelaaja on saavuttanut 10000!';

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
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount noppaa',
      one: '$diceCount nopan',
    );
    return '$playerName perii $_temp0 edelliseltä vuorolta.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Nykyiset pisteet: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nopalla',
      one: '$count nopalla',
    );
    return 'Jatka $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Tämän käden ottaminen ylittäisi jo 10000: et voi lopettaa.';

  @override
  String get restartWithFreshDiceButton => 'Aloita alusta 5 uudella nopalla';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nopalla',
      one: '$count nopalla',
    );
    return 'Jatka $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Aloita alusta 5 uudella nopalla';

  @override
  String get keepDiceButton => 'Säilytä nopat';

  @override
  String get reRollFullHandButton => 'Heitä uudelleen (kuumat nopat)';

  @override
  String get stopButton => 'Lopeta';

  @override
  String get rollDiceButton => 'Heitä noppaa';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noppaa',
      one: '$count noppa',
    );
    return '$_temp0 heitettäväksi';
  }

  @override
  String get bustedTitle => 'Meni pieleen!';

  @override
  String get bustExceedsTarget => 'Tämä heitto ylittäisi 10000.';

  @override
  String get continueButton => 'Jatka';

  @override
  String get howManyFivesToKeep => 'Kuinka monta viittä säilytät?';

  @override
  String get fullHandMustReroll =>
      'Kuumat nopat: sinun täytyy heittää uudelleen!';

  @override
  String get failureBelowMinimum => 'Pisteet liian alhaiset lopettamiseen.';

  @override
  String get failureEndsIn50 =>
      'Et voi lopettaa pisteisiin, jotka päättyvät lukuun 50.';

  @override
  String get failureMustContinueHotDice => 'Sinun täytyy heittää uudelleen.';

  @override
  String get failureNotRolledYet =>
      'Sinun täytyy heittää nopat ennen kuin voit lopettaa.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Lopettaminen nyt tekisi tarkalleen 10000 pisteen saavuttamisesta mahdotonta.';

  @override
  String get settingsMainPlayerTitle => 'Pääpelaaja';

  @override
  String get settingsYourNameLabel => 'Nimesi (laitteen omistaja)';

  @override
  String get settingsDelaysTitle => 'Viiveet';

  @override
  String get settingsDelaysDescription =>
      'Viive ennen kuin automaattinen toiminto laukeaa itsestään. 0 poistaa käytöstä.';

  @override
  String get settingsAiDelayLabel => 'Tekoälyn viestit (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Ihmispelaajan automaattiset toiminnot (ms)';

  @override
  String get settingsDiceTitle => 'Nopat';

  @override
  String get settingsDiceUniform => 'Yhtenäinen';

  @override
  String get settingsDiceVaried => 'Kirjava';

  @override
  String get settingsSoundsTitle => 'Äänet';

  @override
  String get settingsMusicLabel => 'Taustamusiikki';

  @override
  String get settingsSoundEffectsLabel => 'Äänitehosteet';

  @override
  String get settingsPausedGamesTitle => 'Tauolla olevat pelit';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Vahvista ennen pelin poistamista';

  @override
  String get settingsLanguageTitle => 'Kieli';

  @override
  String get settingsLanguageSystemOption => 'Puhelimen kieli';

  @override
  String get diceOffTitle => 'Kuka aloittaa?';

  @override
  String get diceOffInstructions =>
      'Jokainen heittää yhden nopan: alhaisin pistemäärä aloittaa pelin.';

  @override
  String diceOffTieBreak(String names) {
    return 'Tasapeli: $names heittävät uudelleen.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName heittää nopan';
  }

  @override
  String get diceOffRollButton => 'Heitä noppa';

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName aloittaa pelin!';
  }

  @override
  String get gameOverTitle => 'Peli päättyi';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName voittaa!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get newGameButton => 'Uusi peli';

  @override
  String get passDeviceInstruction => 'Anna laite eteenpäin pelaajalle';

  @override
  String get readyButton => 'Valmis';

  @override
  String get notEnteredLabel => '(ei vielä mukana)';

  @override
  String get opportunityTooltip =>
      '200 pisteen päässä yliviivaamasta juuri yläpuolella olevan pelaajan!';

  @override
  String get dangerTooltip =>
      'Vaara: juuri alapuolella oleva pelaaja on vain 200 pisteen päässä, riski että hän viivaa sinut yli';

  @override
  String get tiretTooltip => 'Viiva: toinen epäonnistuminen viivaa pisteet yli';

  @override
  String get previousScoreHadTiretTooltip => 'Edellisissä pisteissä oli viiva';

  @override
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nopalla',
      one: '$count nopalla',
    );
    return 'Todennäköisyys pisteyttää $_temp0';
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
