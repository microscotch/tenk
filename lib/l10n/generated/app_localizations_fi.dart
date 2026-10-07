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
  String get validateButton => 'Vahvista';

  @override
  String get settingsTooltip => 'Asetukset';

  @override
  String get helpTooltip => 'Pelisäännöt';

  @override
  String get aboutTooltip => 'Tietoja';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versio $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Sulje';

  @override
  String playersCountTitle(int count) {
    return 'Pelaajat ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Aloita peli';

  @override
  String get newGameSectionLabel => 'Uusi run...';

  @override
  String get resumeGamesButton => 'Jatka pelejä';

  @override
  String get managePlayersButton => 'Pelaajien hallinta';

  @override
  String get finishedGamesButton => 'Viimeksi päättyneet pelit';

  @override
  String get statisticsButton => 'Tilastot';

  @override
  String playersScreenTitle(int count) {
    return 'Pelaajat ($count)';
  }

  @override
  String get addPlayerTooltip => 'Lisää pelaaja';

  @override
  String get noPlayersMessage => 'Ei vielä tallennettuja pelaajia.';

  @override
  String get newPlayerTitle => 'Uusi pelaaja';

  @override
  String get editPlayerTitle => 'Muokkaa pelaajaa';

  @override
  String get playerNameLabel => 'Nimi';

  @override
  String get playerNicknameLabel => 'Lempinimi (valinnainen)';

  @override
  String get playerNameRequiredError => 'Nimi on pakollinen.';

  @override
  String get playerNameTakenError => 'Toinen pelaaja käyttää jo tätä nimeä.';

  @override
  String get deletePlayerConfirmTitle => 'Poistetaanko tämä pelaaja?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Pelaajan ”$name” tiedot ja tilastot poistetaan pysyvästi. Jo pelatut pelit säilytetään.';
  }

  @override
  String get statsSectionTime => 'Peliaika';

  @override
  String get statsSectionGames => 'Pelit';

  @override
  String get statsSectionFigures => 'Yhdistelmät';

  @override
  String get statsSectionRolls => 'Vuorot ja heitot';

  @override
  String get statsTurns => 'Pelatut vuorot';

  @override
  String get statsRolls => 'Heitot';

  @override
  String get statsRollsPerTurn => 'Heittoja vuorossa';

  @override
  String get statsSectionMisc => 'Urotyöt';

  @override
  String get statsTotalTime => 'Yhteensä';

  @override
  String get statsAverageTime => 'Keskimäärin pelissä';

  @override
  String get statsShortestTime => 'Lyhin';

  @override
  String get statsLongestTime => 'Pisin';

  @override
  String get statsGamesPlayed => 'Pelatut';

  @override
  String get statsGamesWon => 'Voitetut';

  @override
  String get statsGamesLost => 'Hävityt';

  @override
  String get statsLoneAces => 'Säilytetyt yksittäiset ykköset';

  @override
  String get statsLoneFives => 'Säilytetyt yksittäiset viitoset';

  @override
  String get statsBrelans => 'Kolmoset';

  @override
  String get statsCarres => 'Neloset';

  @override
  String get statsQuintes => 'Viisi samaa';

  @override
  String get statsSuites => 'Suorat';

  @override
  String get statsSmallSuites => 'joista pieniä';

  @override
  String get statsBigSuites => 'joista suuria';

  @override
  String get statsAceQuints => 'Viisi ykköstä';

  @override
  String get statsAceQuintsWon => 'joista voittoon';

  @override
  String get statsBestTurn => 'Paras vuoro';

  @override
  String get statsHotDiceRun => 'Kuumat nopat peräkkäin';

  @override
  String get statsBusts => 'Epäonnistumiset';

  @override
  String get statsLongestBustStreak => 'pisin putki';

  @override
  String get statsSelfBars => 'Itse yliviivatut';

  @override
  String get statsBarsInflicted => 'Muilta yliviivatut';

  @override
  String get scoreChartTitle => 'Pisteiden kehitys';

  @override
  String get gameStatsTitle => 'Pelin tilastot';

  @override
  String get gameStatsGameSection => 'Peli';

  @override
  String get gameStatsFiguresSection => 'Pelin yhdistelmät';

  @override
  String get gameStatsDuration => 'Peliaika';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns vuoroa',
      one: '$turns vuoro',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts epäonnistumista',
      one: '$busts epäonnistuminen',
    );
    return '$_temp0 · paras $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games peliä',
      one: '$games peli',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won voitettua',
      one: '$won voitettu',
    );
    return '$_temp0 · $_temp1 · paras $best';
  }

  @override
  String get scoreChartEmpty =>
      'Yhtään vuoroa ei ole vielä päättynyt: piirrettävää ei ole.';

  @override
  String get replayUnavailable =>
      'Tätä peliä ei voi katsoa uudelleen: sen loki on puutteellinen.';

  @override
  String get replayPlay => 'Toista';

  @override
  String get replayPause => 'Tauko';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Vuoro $turn';
  }

  @override
  String get scoreChartXAxis => 'Pelatut vuorot';

  @override
  String get statsBreakdownRow => 'joista';

  @override
  String get statsRecordsTitle => 'Ennätykset';

  @override
  String get statsNoRecordYet => 'Ei vielä ennätyksiä.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Valitse pelaajat';

  @override
  String get addHumanTooltip => 'Lisää pelaaja';

  @override
  String get addBotTooltip => 'Lisää botti';

  @override
  String get createPlayerButton => 'Uusi pelaaja';

  @override
  String get noPlayersToPickMessage =>
      'Ei tallennettuja pelaajia. Luo yksi aloittaaksesi.';

  @override
  String get botLabel => 'Botti';

  @override
  String get removeSeatTooltip => 'Poista pelistä';

  @override
  String get notEnoughPlayersMessage => 'Tarvitaan vähintään kaksi pelaajaa.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pelattua peliä',
      one: '$count pelattu peli',
      zero: 'Ei pelattuja pelejä',
    );
    return '$_temp0';
  }

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
  String get gameRunParticipantsSeparator => ' vs ';

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
  String get resumeLastGameDialogTitle => 'Jatketaanko peliä?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Peli ”$alias” on kesken. Haluatko jatkaa sitä?';
  }

  @override
  String get resumeGameButton => 'Jatka';

  @override
  String get gameOverReplayButton => 'Katso peli uudelleen';

  @override
  String get scoreGridLabel => 'Pistetaulukko';

  @override
  String get finalRoundBanner =>
      'Viimeinen kierros: pelaaja on saavuttanut 10000!';

  @override
  String get currentRollZoneLabel => 'Rata';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Rata ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Nykyinen käsi';

  @override
  String get logHotDiceMessage => 'Kuumat nopat!';

  @override
  String get logScoreCollisionMessage => 'Pisteet yliviivattu:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noppaa',
      one: '$count noppa',
    );
    return '$kept: $gain, $_temp0 => $total p';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, kuumat nopat => $total p';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score p kirjattu => $total p';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score p otettu haltuun';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Meni pieleen! => $score viiva';
  }

  @override
  String get logBustBarredPrefix => 'Meni pieleen! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'takaisin $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Tämän käden ottaminen ylittäisi jo 10000: et voi lopettaa.';

  @override
  String get rollButton => 'Heitä';

  @override
  String get showProbabilitiesSetting => 'Näytä todennäköisyydet';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Näyttää ”Heitä”-painikkeessa todennäköisyyden saada vähintään yksi piste';

  @override
  String get stopButton => 'Lopeta';

  @override
  String get bustedTitle => 'Meni pieleen!';

  @override
  String get bustExceedsTarget => 'Tämä heitto ylittäisi 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Kuumat nopat 10000 pisteessä: et voi lopettaa, ja kaikkien heittäminen uudelleen ylittäisi.';

  @override
  String get bustContinueButton => 'Jatka';

  @override
  String get inheritedHandDialogTitle => 'Otatko haltuun?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count noppaa',
      one: '$count noppa',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Ota käsi haltuun';

  @override
  String get newHandButton => 'Uusi käsi';

  @override
  String get failureBelowMinimum => 'Pisteet liian alhaiset lopettamiseen.';

  @override
  String get failureEndsIn50 =>
      'Et voi lopettaa pisteisiin, jotka päättyvät lukuun 50.';

  @override
  String get failureMustContinueHotDice => 'Sinun täytyy heittää uudelleen.';

  @override
  String get failureMustContinueFinalRound =>
      'Et voi lopettaa: viimeinen kierros vaatii tarkalleen 10000 pistettä.';

  @override
  String get failureNotRolledYet =>
      'Sinun täytyy heittää nopat ennen kuin voit lopettaa.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Lopettaminen nyt tekisi tarkalleen 10000 pisteen saavuttamisesta mahdotonta.';

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
  String get settingsHandednessLabel => 'Painikkeiden asettelu';

  @override
  String get settingsHandednessRight => 'Oikeakätinen';

  @override
  String get settingsHandednessLeft => 'Vasenkätinen';

  @override
  String get settingsControlsTitle => 'Ohjaimet';

  @override
  String get settingsShakeToRollLabel => 'Heitä nopat ravistamalla';

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
  String get reorderPlayersHint =>
      'Vedä pelaajaa kahvasta muuttaaksesi järjestystä pöydän ympärillä.';

  @override
  String get reorderPlayerHandleLabel => 'Siirrä tätä pelaajaa';

  @override
  String get diceOffTitle => 'Kuka aloittaa?';

  @override
  String get diceOffInstructions =>
      'Kaikki heittävät noppaa samaan aikaan: pienin aloittaa. Tasapelissä tasoihin jääneet heittävät uudelleen.';

  @override
  String diceOffTieBreak(String names) {
    return 'Tasapeli: $names heittävät uudelleen.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName aloittaa pelin!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Pelijärjestys';

  @override
  String get diceOffReversedNote =>
      'Naapureiden kaksintaistelun voitti jälkimmäinen: peli kiertää toiseen suuntaan.';

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
  String get rankFirstTooltip => 'Johdossa';

  @override
  String get rankSecondTooltip => '2. pisteissä';

  @override
  String get rankThirdTooltip => '3. pisteissä';

  @override
  String get rulesScreenTitle => 'Pelisäännöt';

  @override
  String get tutorialTitle => 'Opastus';

  @override
  String get tutorialSkip => 'Ohita';

  @override
  String get tutorialNext => 'Seuraava';

  @override
  String get tutorialRoll => 'Heitä nopat';

  @override
  String get tutorialKeep => 'Pidä';

  @override
  String get tutorialFinish => 'Aloita pelaaminen';

  @override
  String get tutorialReplayButton => 'Katso opastus uudelleen';

  @override
  String get tutorialStep0 =>
      'Tervetuloa Le 10000 -peliin! Tavoite: saavuttaa tasan 10 000 pistettä. Pelaamme yhden vuoron yhdessä; mitään täällä tekemääsi ei tallenneta.';

  @override
  String get tutorialStep1 =>
      'Omalla vuorollasi heität 5 noppaa. Napauta ”Heitä nopat”.';

  @override
  String get tutorialStep2 =>
      'Tässä pisteitä tuovat vain ykkönen (100 pistettä) ja viitonen (50 pistettä). Ykkönen on pakollinen; viitosen voisi jättää sivuun, mutta pidetään se. Napauta ”Pidä”.';

  @override
  String get tutorialStep3 =>
      'Nykyinen käsi on 150 pisteen arvoinen ja 3 noppaa on jäljellä heitettäväksi. Peliin pääsyyn tarvitaan vähintään 500 pistettä: heitetään uudelleen.';

  @override
  String get tutorialStep4 =>
      'Kolme samaa noppaa: kolme kolmosta on 300 pistettä. Pidä ne.';

  @override
  String get tutorialStep5 =>
      'Kaikki nopat toivat pisteitä: kuumat nopat! Sinun on heitettävä kaikki 5 noppaa uudelleen etkä voi lopettaa. Nykyinen käsi säilyttää 450 pistettään.';

  @override
  String get tutorialStep6 =>
      'Kaksi ykköstä ja viitonen: 250 lisää, eli 700. Viitosen pitäminen kannattaa: lopettaminen lukuun 650 olisi kiellettyä (ei koskaan summaa, joka päättyy lukuun 50).';

  @override
  String get tutorialStep7 =>
      '700 pistettä: yli 500 eikä 50 lopussa. Voit lopettaa ja kirjata ne. Napauta ”Lopeta”.';

  @override
  String get tutorialStep8 =>
      '700 pistettä kirjattu! Katsotaan nyt, mitä tapahtuu, kun nopat eivät tuo mitään: heitä.';

  @override
  String get tutorialStep9 =>
      'Mikään noppa ei tuo pisteitä: epäonnistuminen! Vuoro menetetään ja viiva merkitsee pisterivisi; toinen epäonnistuminen yliviivaisi sen. Ensimmäinen, joka saavuttaa tasan 10 000, käynnistää muille loppukierroksen. Täydelliset säännöt ovat valikossa. Hauskaa peliä!';

  @override
  String get rulesGoalTitle => 'Pelin tavoite';

  @override
  String get rulesGoalBody =>
      'Saavuta tasan 10 000 pistettä. Ylittäminen ei kelpaa.';

  @override
  String get rulesTurnTitle => 'Miten vuoro pelataan';

  @override
  String get rulesTurnBody =>
      'Heität 5 noppaa, otat sivuun vähintään yhden pisteitä tuovan nopan ja heität sitten loput uudelleen tai lopetat ja kirjaat pisteet. Jos heitto ei tuo mitään, se on epäonnistuminen: menetät kaiken tällä vuorolla kertyneen.';

  @override
  String get rulesScoringTitle => 'Mikä tuo pisteitä';

  @override
  String get rulesScoringBody =>
      '• Yksittäinen ykkönen: 100 pistettä. Yksittäinen viitonen: 50 pistettä. Muut yksittäiset silmäluvut (2, 3, 4, 6) eivät tuo mitään.\n• Kolme samaa: silmäluku × 100 (kolme kutosta on 600), paitsi kolme ykköstä: 1000.\n• Neljä samaa: 1000 pistettä enemmän kuin vastaavat kolme samaa (neljä kutosta on 1600, neljä ykköstä 2000).\n• Viisi samaa on silmäluku × 1000. Viisi ykköstä tuo suoraan 10 000 pistettä: välitön voitto.\n• Viiden peräkkäisen nopan suora (1-2-3-4-5 tai 2-3-4-5-6) on 500 pistettä.';

  @override
  String get rulesBustTitle => 'Epäonnistuminen ja yliviivaus';

  @override
  String get rulesBustBody =>
      'Epäonnistuminen merkitsee nykyisen pisterivisi viivalla. Jos rivillä oli jo viiva, se yliviivataan ja pisteesi palaavat edelliseen arvoon. Jos saavutat saman summan kuin toinen pelaaja, hänet yliviivataan.';

  @override
  String get rulesEntryTitle => 'Lopettaminen';

  @override
  String get rulesEntryBody =>
      '• Peliin pääsyyn tarvitaan vähintään 500 pistettä, sen jälkeen vähintään 200 vuorolla.\n• Et voi koskaan lopettaa vuoron summaan, joka päättyy lukuun 50 (250, 450…).\n• Jos kaikki nopat tuovat pisteitä (”kuumat nopat”), sinun on heitettävä kaikki 5 uudelleen.';

  @override
  String get rulesExtensionTitle => 'Laajennussääntö';

  @override
  String get rulesExtensionBody =>
      'Kun olet kirjannut kolme tai neljä samaa, jokainen yksittäinen samanarvoinen noppa myöhemmin samalla vuorolla on 100 pisteen arvoinen, myös viitonen. Kuumat nopat lopettavat tämän.';

  @override
  String get rulesInheritTitle => 'Edellisen pelaajan noppien periminen';

  @override
  String get rulesInheritBody =>
      'Jos lopetat heittämättömien noppien kanssa, seuraava pelaaja voi ottaa ne ja pisteesi lähtöpohjaksi tai aloittaa 5 uudella nopalla. Epäonnistumisen jälkeen hän aloittaa aina 5 uudella nopalla.';

  @override
  String get rulesVictoryTitle => 'Tasan 10 000 ja loppukierros';

  @override
  String get rulesVictoryBody =>
      'Heti kun heitto mahdollistaa tasan 10 000 pisteen saavuttamisen, otto tapahtuu automaattisesti ja vuoro päättyy. Muilla pelaajilla on sitten viimeinen vuoro tasoittaa tulos: siinä kukaan ei voi lopettaa alle 10 000:n, on tasoitettava tai epäonnistuttava. Jos toinenkin pelaaja saavuttaa tasan 10 000, hän yliviivaa ensimmäisen ja hänen ympärillään alkaa uusi loppukierros.\nErikoistapaus: täysi käsi, joka osuu tasan 10 000:een, on epäonnistuminen, koska se pakottaa heittämään uudelleen. Vain viiden ässän sarja voittaa.';

  @override
  String get onlinePlayButton => 'Pelaa verkossa';

  @override
  String get onlineResumeButton => 'Jatka verkkopeliä';

  @override
  String get onlineTitle => 'Verkkopeli';

  @override
  String get onlineCreateButton => 'Luo huone';

  @override
  String get onlineJoinButton => 'Liity';

  @override
  String get onlineCodeLabel => 'Huoneen koodi';

  @override
  String get onlineOrDivider => 'tai';

  @override
  String get onlineShareHint =>
      'Anna tämä koodi muille pelaajille, niin he voivat liittyä.';

  @override
  String get onlineShareButton => 'Jaa koodi';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Liity verkkopeliini Le 10000! Huoneen koodi: $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Pelaajat ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Isäntä';

  @override
  String get onlineDisconnectedBadge => 'Yhteys katkennut';

  @override
  String get onlineNeedTwoPlayers =>
      'Tarvitaan vähintään 2 pelaajaa, kaikki yhteydessä.';

  @override
  String get onlineWaitingForHost => 'Odotetaan, että isäntä aloittaa…';

  @override
  String get onlineLeaveButton => 'Poistu';

  @override
  String get onlineLeaveConfirmTitle => 'Poistutaanko verkkopelistä?';

  @override
  String get onlineLeaveConfirmBody =>
      'Aloitetussa pelissä paikkasi jää tyhjäksi ja peli odottaa paluutasi.';

  @override
  String get onlineConnecting => 'Yhdistetään palvelimeen…';

  @override
  String get onlineReconnecting => 'Yhteys katkesi, yhdistetään uudelleen…';

  @override
  String get onlineSuspended =>
      'Peli keskeytetty: pelaaja on ollut poissa liian kauan.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName pelaa…';
  }

  @override
  String get onlineDiceOffContinue => 'Pelaa';

  @override
  String get onlineErrorUnreachable => 'Palvelimeen ei saada yhteyttä.';

  @override
  String get onlineErrorRoomNotFound => 'Tällä koodilla ei ole huonetta.';

  @override
  String get onlineErrorRoomFull => 'Tämä huone on täynnä.';

  @override
  String get onlineErrorGameStarted => 'Tämä peli on jo alkanut.';

  @override
  String get onlineErrorRateLimited =>
      'Liian monta yritystä: yritä hetken päästä uudelleen.';

  @override
  String get onlineErrorBadToken => 'Paikkaasi tässä huoneessa ei enää ole.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Päivitä sovellus pelataksesi verkossa.';

  @override
  String get onlineErrorGeneric => 'Tapahtui virhe.';

  @override
  String get myProfileTitle => 'Oma profiili';

  @override
  String get myProfileWelcomeTitle => 'Tervetuloa!';

  @override
  String get myProfileWelcomeMessage =>
      'Luo profiilisi: nimesi, halutessasi lempinimi ja käsi, jolla pelaat. Verkossa muut pelaajat näkevät lempinimesi tai nimesi, jos sinulla ei ole lempinimeä.';

  @override
  String get myProfileExistingPrompt =>
      'Oletko jo pelaajaluettelossa? Napauta nimeäsi.';

  @override
  String get myProfileCreateButton => 'Luo oma profiili';

  @override
  String get myProfileEditButton => 'Muokkaa omaa profiilia';

  @override
  String get myProfileBadge => 'Minä';

  @override
  String onlinePlayingAs(String name) {
    return 'Pelaat nimellä ”$name”';
  }

  @override
  String get onlineNameInvalidError =>
      'Verkossa lempinimesi (tai nimesi) saa olla enintään 20 merkkiä, ilman näkymättömiä merkkejä.';

  @override
  String get settingsDiceSoundLabel => 'Noppien ääni';

  @override
  String get settingsDiceSoundRealistic => 'Realistinen';

  @override
  String get settingsDiceSoundSynthetic => 'Synteettinen';

  @override
  String get homeChipsHint => 'Paina pelimerkkiä pitkään nähdäksesi sen nimen.';

  @override
  String get emoteThoughtful => 'Mietteliäs';

  @override
  String get emoteMocking => 'Kuolen nauruun';

  @override
  String get emoteDevastated => 'Murtunut';

  @override
  String get emoteJoyful => 'Halaus';

  @override
  String get emotePhraseCoincidence => 'Mikä sattuma...';

  @override
  String get emotePhraseStickyFive => 'Viitonen tarttuu!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Täysi käsi, tyhjä käsi!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Tuhatta ei koskaan oteta!';

  @override
  String get emotePhraseNoWay => 'Yksinkertaisesti mahdotonta!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Moi!';

  @override
  String get emotePhraseYes => 'Jes!';

  @override
  String get emotePhraseTooGreedy => 'Liian ahne!';

  @override
  String get emotePhraseTooLucky => 'Vähän liian onnekas...';

  @override
  String get emotePhraseDryTenThousand => 'Suoraan 10000:een';

  @override
  String get emotePhraseLucky => 'Onnenpekka!';

  @override
  String get emotePhraseGoodLuck => 'Onnea!';

  @override
  String get emotePhraseThanks => 'Kiitos';

  @override
  String get emotePhraseSorryMustGo => 'Sori, mutta minun täytyy lähteä';

  @override
  String get gameHistoryBar => 'Historia';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'Uusi versio on saatavilla ($version, koontiversio $build).';
  }

  @override
  String get updateNowButton => 'Päivitä';

  @override
  String get updateLaterButton => 'Myöhemmin';
}
