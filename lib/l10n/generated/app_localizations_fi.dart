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
  String rollButtonHotDiceTotal(int total) {
    return 'Kuumat nopat! → $total';
  }

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
  String logBustMessage(int lost) {
    return '$lost: Meni pieleen!';
  }

  @override
  String logBustTiretMessage(int lost, int score) {
    return '$lost: Meni pieleen! => $score viiva';
  }

  @override
  String logBustBarredPrefix(int lost) {
    return '$lost: Meni pieleen! =>';
  }

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
  String get radarTargetsTooltip =>
      'Pisteet, jotka käynnissä oleva käsi voisi yliviivata';

  @override
  String get radarGapTooltip => 'Ero käynnissä olevan käden summaan';

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
  String get tutorialFinalOutro =>
      'Botti on yliviivattu ja sen on nyt yritettävä 10 000:ta. Nyt osaat kaikki säännöt: hauskaa peliä!';

  @override
  String get tutorialFinalExact =>
      'Kolme nelosta: tasan 10 000! Se otetaan automaattisesti.';

  @override
  String get tutorialFinalNoStop =>
      '100: 9600. Viimeisellä kierroksella ei voi lopettaa: heitä uudelleen.';

  @override
  String get tutorialFinalIntro =>
      'Botti on saavuttanut 10 000: tämä on viimeinen kierros. Voittaaksesi sinun on tasattava se, mikä yliviivaa sen. Lopettaminen ennen sitä on kielletty.';

  @override
  String get tutorialCollisionOutro =>
      'Botti on yliviivattu ja putoaa takaisin 1500:aan. Toisen pelaajan rivin saavuttaminen, vanhankin, yliviivaa myös sen.';

  @override
  String get tutorialCollisionCollide =>
      'Kaksi ykköstä: 200. Olisit 2000:ssa, botin tuloksessa, punaisella sen tutkassa. Lopeta yliviivataksesi sen.';

  @override
  String get tutorialCollisionIntro =>
      'Botin rivillä tutka näyttää sen tulokset, jotka voisit yliviivata: saman summan saavuttaminen pudottaa sen takaisin.';

  @override
  String get tutorialInheritOutro =>
      'Epäonnistumisen jälkeen aloitetaan aina 5 uudella nopalla. Kättä, jota ei enää voisi kirjata, ei koskaan tarjota.';

  @override
  String get tutorialInheritStop =>
      'Ykkönen: käsi on 1100 pisteen arvoinen. Lopeta.';

  @override
  String get tutorialInheritTake =>
      'Botti lopetti 1000:een jättäen 2 noppaa. Ota käsi: aloitat sen 1000 pisteestä, ja 2 noppaa heitetään heti (ennen lopettamista heitetään aina vähintään kerran).';

  @override
  String get tutorialInheritIntro =>
      'Kun pelaaja lopettaa jättäen noppia, seuraava voi ottaa ne, hänen pisteensä pohjana.';

  @override
  String get tutorialExtensionOutro =>
      'Laajennus kestää koko vuoron, myös viitoselle (100 eikä 50), ja häviää kuumissa nopissa.';

  @override
  String get tutorialExtensionExtended =>
      'Yksittäinen kakkonen ei ole minkään arvoinen… paitsi tässä: kolmen kakkosesi jälkeen se on 100 pisteen arvoinen (punaisella). Käsi on 300: lopeta.';

  @override
  String get tutorialExtensionBrelan =>
      'Kolme kakkosta: 200. Heitä 2 viimeistä noppaa uudelleen.';

  @override
  String get tutorialExtensionIntro =>
      'Kolmen saman jälkeen yksittäinen samanarvoinen noppa myöhemmin samalla vuorolla on 100 pisteen arvoinen.';

  @override
  String get tutorialBustOutro =>
      'Epäonnistuminen merkitsee rivin viivalla; toinen yliviivaa sen. Nollassa epäonnistuminen ei maksa mitään.';

  @override
  String get tutorialBustBarred =>
      'Toinen epäonnistuminen: 1500:n rivi on yliviivattu, putoat takaisin 500:aan, edelliseen tulokseesi. Napauta ✓.';

  @override
  String get tutorialBustRollAgain =>
      'Rivilläsi on viiva: toinen epäonnistuminen yliviivaisi sen. Heitä silti.';

  @override
  String get tutorialBustTiret =>
      'Meni pieleen! Käsi menetetään, ja 1500 pisteen rivisi saa viivan. Napauta ✓.';

  @override
  String get tutorialBustIntro =>
      'Heitto ilman pisteitä on epäonnistuminen: käynnissä oleva käsi menetetään. Sinulla on 1500 pistettä.';

  @override
  String get tutorialHotDiceOutro =>
      'Muista: älä koskaan lopeta summaan, joka päättyy lukuun 50, ja kuumat nopat heitetään aina uudelleen.';

  @override
  String get tutorialHotDiceStop =>
      '500: riittää sisään, eikä lopussa ole 50. Lopeta.';

  @override
  String get tutorialHotDiceFives =>
      'Kaksi viitosta, mutta vapaaehtoisia: tämä valitsin määrää, montako pidät. Molemmilla 550 päättyisi lukuun 50: et voisi lopettaa. Valitse 1.';

  @override
  String get tutorialHotDiceFullHand =>
      'Kolme kolmosta: 300, käsi nousee 450:een. Kaikki nopat toivat pisteitä: kuumat nopat! Painike näyttää summan, joka sinulla olisi; kaikki 5 heitetään uudelleen etkä voi lopettaa.';

  @override
  String get tutorialHotDiceKept =>
      'Ykkönen ja viitonen pidetään: käsi on 150 pisteen arvoinen. Heitä muut 3 noppaa uudelleen.';

  @override
  String get tutorialHotDiceIntro =>
      'Kun kaikki nopat tuovat pisteitä, ne ovat kuumat nopat: kaikki 5 heitetään uudelleen. Ja yksittäinen viitonen on joskus vapaaehtoinen.';

  @override
  String get tutorialBasicsOutro =>
      '700 pistettä kirjattu: olet pelissä! Tästä lähtien jokaisen vuoron on tuotava vähintään 200 pistettä.';

  @override
  String get tutorialBasicsBrelan =>
      'Kolme kuutosta: kolme samaa on 100 kertaa silmäluvun arvoinen, tässä 600 (kolme ykköstä: 1000). Käsi on 700 pisteen arvoinen, riittää sisään: napauta kättä lopettaaksesi.';

  @override
  String get tutorialBasicsAce =>
      'Yksinään pisteitä tuovat vain ykkönen (100) ja viitonen (50): ykkönen pannaan sivuun. Peliin pääsyyn tarvitaan 500 pistettä yhdellä vuorolla: heitä muut 4 noppaa uudelleen.';

  @override
  String get tutorialBasicsIntro =>
      'Tervetuloa Le 10000 -peliin! Tavoite: saavuttaa tasan 10 000 pistettä. Joka vuorolla heitetään 5 noppaa ja pisteitä tuovat nopat pannaan sivuun.';

  @override
  String get tutorialLessonFinalRound => 'Viimeinen kierros';

  @override
  String get tutorialLessonCollision => 'Pelaajan yliviivaaminen';

  @override
  String get tutorialLessonInheritedHand => 'Peritty käsi';

  @override
  String get tutorialLessonExtension => 'Laajennussääntö';

  @override
  String get tutorialLessonBust => 'Epäonnistuminen';

  @override
  String get tutorialLessonHotDice => 'Kuumat nopat';

  @override
  String get tutorialLessonBasics => 'Perusteet';

  @override
  String get tutorialBotTurn => 'Botin vuoro: se pelaa itse.';

  @override
  String get tutorialRollPrompt => 'Napauta heittopainiketta.';

  @override
  String get tutorialWholePath => 'Koko opastus';

  @override
  String get tutorialLessonsTitle => 'Opastuksen oppitunnit';

  @override
  String get tutorialNextLesson => 'Seuraava oppitunti';

  @override
  String tutorialLessonCounter(int number, int total, String title) {
    return 'Oppitunti $number/$total: $title';
  }

  @override
  String get tutorialPlayerName => 'Sinä';

  @override
  String get tutorialNext => 'Seuraava';

  @override
  String get tutorialFinish => 'Aloita pelaaminen';

  @override
  String get tutorialReplayButton => 'Opastuksen oppitunnit';

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
  String get onlineLeaveGameBody =>
      'Poistut huoneesta: botti pelaa puolestasi pelin loppuun asti.';

  @override
  String get onlineDiceOffWaitingStart => 'Odotetaan pelin alkua';

  @override
  String get logPlayerReplacedByBot =>
      'poistui pelistä: botti pelaa hänen puolestaan';

  @override
  String get botSeatTooltip => 'Botin pelaama (pelaaja poistui)';

  @override
  String get rematchButton => 'Pelaa uudelleen';

  @override
  String rematchProposal(String name) {
    return '$name ehdottaa revanssia';
  }

  @override
  String get rematchWaiting => 'Odotetaan muita pelaajia…';

  @override
  String rematchSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get rematchAccept => 'Hyväksy';

  @override
  String get rematchRefuse => 'Hylkää';

  @override
  String get rematchExcludedNotice =>
      'Poistuit huoneesta: ei revanssia sinulle.';

  @override
  String get rematchCancelledNotice =>
      'Ei revanssia: tarvitaan vähintään kaksi pelaajaa.';

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
  String get emotePhraseTooGreedy => 'Ahneus on ruma vika!';

  @override
  String get emotePhraseTooLucky => 'Vähän liikaa onnea...';

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
  String get emoteAngry => 'Vihainen';

  @override
  String get emoteRelieved => 'Helpottunut';

  @override
  String get emotePhraseStrangeChoice => 'Mikä ihmeen outo valinta tämä on?';

  @override
  String get emotePhraseAllByFives => 'Kaikki viitosilla!';

  @override
  String get emotePhraseWithPanache => 'Tyylillä!';

  @override
  String get emotePhraseUnfair => 'Tämä on todella epäreilua';

  @override
  String get emotePhrasePhew => 'Huh!';

  @override
  String get emotePhraseAtLast => 'Vihdoinkin!';

  @override
  String get emotePhraseCloseCall => 'Olipa täpärällä!';

  @override
  String get emotePhraseWellPlayed => 'Hyvin pelattu';

  @override
  String get emotePhraseSorry => 'Anteeksi';

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
