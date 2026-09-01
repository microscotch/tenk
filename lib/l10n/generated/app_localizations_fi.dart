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
  String get pausedGamesSectionLabel => 'Keskeytyneet runit';

  @override
  String get finishedRunsSectionLabel => 'Päättyneet runit';

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
  String turnScoreLabel(int score) {
    return 'Vuoron pisteet: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Vaadittu minimi: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Tällä vuorolla säästetyt nopat';

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
  String thisRollScoreLabel(int score) {
    return 'Tämän heiton pisteet: $score';
  }

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
}
