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
  String get validateButton => 'Confirmă';

  @override
  String get settingsTooltip => 'Setări';

  @override
  String get helpTooltip => 'Regulile jocului';

  @override
  String get aboutTooltip => 'Despre';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versiunea $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Închide';

  @override
  String playersCountTitle(int count) {
    return 'Jucători ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Începe jocul';

  @override
  String get newGameSectionLabel => 'Run nou...';

  @override
  String get resumeGamesButton => 'Reluare jocuri';

  @override
  String get managePlayersButton => 'Gestionare jucători';

  @override
  String get finishedGamesButton => 'Ultimele jocuri terminate';

  @override
  String get statisticsButton => 'Statistici';

  @override
  String playersScreenTitle(int count) {
    return 'Jucători ($count)';
  }

  @override
  String get addPlayerTooltip => 'Adaugă un jucător';

  @override
  String get noPlayersMessage => 'Niciun jucător salvat momentan.';

  @override
  String get newPlayerTitle => 'Jucător nou';

  @override
  String get editPlayerTitle => 'Editează jucătorul';

  @override
  String get playerNameLabel => 'Nume';

  @override
  String get playerNicknameLabel => 'Poreclă (opțional)';

  @override
  String get playerNameRequiredError => 'Numele este obligatoriu.';

  @override
  String get playerNameTakenError =>
      'Acest nume este deja folosit de alt jucător.';

  @override
  String get deletePlayerConfirmTitle => 'Ștergi acest jucător?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Fișa lui „$name” și statisticile sale vor fi șterse definitiv. Jocurile deja jucate se păstrează.';
  }

  @override
  String get statsSectionTime => 'Timp de joc';

  @override
  String get statsSectionGames => 'Jocuri';

  @override
  String get statsSectionFigures => 'Combinații';

  @override
  String get statsSectionRolls => 'Ture și aruncări';

  @override
  String get statsTurns => 'Ture jucate';

  @override
  String get statsRolls => 'Aruncări';

  @override
  String get statsRollsPerTurn => 'Aruncări pe tură';

  @override
  String get statsSectionMisc => 'Isprăvi';

  @override
  String get statsTotalTime => 'Total';

  @override
  String get statsAverageTime => 'Medie pe joc';

  @override
  String get statsShortestTime => 'Cel mai scurt';

  @override
  String get statsLongestTime => 'Cel mai lung';

  @override
  String get statsGamesPlayed => 'Jucate';

  @override
  String get statsGamesWon => 'Câștigate';

  @override
  String get statsGamesLost => 'Pierdute';

  @override
  String get statsLoneAces => '1 izolați păstrați';

  @override
  String get statsLoneFives => '5 izolați păstrați';

  @override
  String get statsBrelans => 'Triplete';

  @override
  String get statsCarres => 'Careuri';

  @override
  String get statsQuintes => 'Chinte';

  @override
  String get statsSuites => 'Suite';

  @override
  String get statsSmallSuites => 'dintre care mici';

  @override
  String get statsBigSuites => 'dintre care mari';

  @override
  String get statsAceQuints => 'Cinci de 1';

  @override
  String get statsAceQuintsWon => 'dintre care câștigătoare';

  @override
  String get statsBestTurn => 'Cea mai bună tură';

  @override
  String get statsHotDiceRun => 'Zaruri fierbinți la rând';

  @override
  String get statsBusts => 'Eșecuri';

  @override
  String get statsLongestBustStreak => 'cea mai lungă serie';

  @override
  String get statsSelfBars => 'Tăiați singuri';

  @override
  String get statsBarsInflicted => 'Tăiați altora';

  @override
  String get scoreChartTitle => 'Evoluția scorurilor';

  @override
  String get gameStatsTitle => 'Statisticile jocului';

  @override
  String get gameStatsGameSection => 'Joc';

  @override
  String get gameStatsFiguresSection => 'Combinațiile jocului';

  @override
  String get gameStatsDuration => 'Timp de joc';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns de ture',
      few: '$turns ture',
      one: '$turns tură',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts de eșecuri',
      few: '$busts eșecuri',
      one: '$busts eșec',
    );
    return '$_temp0 · cel mai bun $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games de jocuri',
      few: '$games jocuri',
      one: '$games joc',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won câștigate',
      few: '$won câștigate',
      one: '$won câștigat',
    );
    return '$_temp0 · $_temp1 · cel mai bun $best';
  }

  @override
  String get scoreChartEmpty =>
      'Nicio tură încheiată momentan: încă nu e nimic de trasat.';

  @override
  String get replayUnavailable =>
      'Acest joc nu poate fi revăzut: jurnalul său este incomplet.';

  @override
  String get replayPlay => 'Redă';

  @override
  String get replayPause => 'Pauză';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Tura $turn';
  }

  @override
  String get scoreChartXAxis => 'Ture jucate';

  @override
  String get statsBreakdownRow => 'dintre care';

  @override
  String get statsRecordsTitle => 'Recorduri';

  @override
  String get statsNoRecordYet => 'Niciun record momentan.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Alege jucătorii';

  @override
  String get addHumanTooltip => 'Adaugă un jucător';

  @override
  String get addBotTooltip => 'Adaugă un bot';

  @override
  String get createPlayerButton => 'Jucător nou';

  @override
  String get noPlayersToPickMessage =>
      'Niciun jucător salvat. Creează unul pentru a începe.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Scoate din joc';

  @override
  String get notEnoughPlayersMessage => 'Sunt necesari cel puțin doi jucători.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de jocuri jucate',
      few: '$count jocuri jucate',
      one: '$count joc jucat',
      zero: 'Niciun joc jucat',
    );
    return '$_temp0';
  }

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
  String get gameRunParticipantsSeparator => ' vs ';

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
  String get resumeLastGameDialogTitle => 'Reiei jocul?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Un joc „$alias” este în desfășurare. Vrei să-l reiei?';
  }

  @override
  String get resumeGameButton => 'Reia';

  @override
  String get gameOverReplayButton => 'Revezi jocul';

  @override
  String get scoreGridLabel => 'Grilă de scoruri';

  @override
  String get finalRoundBanner => 'Ultima rundă: un jucător a atins 10000!';

  @override
  String get currentRollZoneLabel => 'Pistă';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Pistă ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Mâna curentă';

  @override
  String get logHotDiceMessage => 'Zaruri fierbinți!';

  @override
  String rollButtonHotDiceTotal(int total) {
    return 'Zaruri fierbinți! → $total';
  }

  @override
  String get logScoreCollisionMessage => 'Scor tăiat:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return '$kept: $gain, $_temp0 => $total pct';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, zaruri fierbinți => $total pct';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score pct încasate => $total pct';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score pct reluate';
  }

  @override
  String logBustMessage(int lost) {
    return '$lost: Ai ars!';
  }

  @override
  String logBustTiretMessage(int lost, int score) {
    return '$lost: Ai ars! => $score liniuță';
  }

  @override
  String logBustBarredPrefix(int lost) {
    return '$lost: Ai ars! =>';
  }

  @override
  String logBustBarredReturnMessage(int score) {
    return 'înapoi la $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Reluarea acestei mâini ar depăși deja 10000: nu te poți opri.';

  @override
  String get rollButton => 'Aruncă';

  @override
  String get showProbabilitiesSetting => 'Afișează probabilitățile';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Afișează pe butonul „Aruncă” șansa de a marca cel puțin un punct';

  @override
  String get stopButton => 'Oprește-te';

  @override
  String get bustedTitle => 'Ai ars!';

  @override
  String get bustExceedsTarget => 'Această aruncare ar depăși 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Zaruri fierbinți la 10000: nu te poți opri, iar aruncarea tuturor din nou ar depăși.';

  @override
  String get bustContinueButton => 'Continuă';

  @override
  String get inheritedHandDialogTitle => 'Reiei?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Reia mâna';

  @override
  String get newHandButton => 'Mână nouă';

  @override
  String get failureBelowMinimum => 'Scor insuficient pentru a te opri.';

  @override
  String get failureEndsIn50 =>
      'Nu te poți opri la un scor care se termină în 50.';

  @override
  String get failureMustContinueHotDice => 'Trebuie să arunci din nou.';

  @override
  String get failureMustContinueFinalRound =>
      'Nu te poți opri: ultima rundă necesită să atingi exact 10000.';

  @override
  String get failureNotRolledYet =>
      'Trebuie să arunci zarurile înainte de a te putea opri.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Oprirea acum ar face imposibilă atingerea exactă a 10000.';

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
  String get settingsHandednessLabel => 'Dispunerea butoanelor';

  @override
  String get settingsHandednessRight => 'Dreptaci';

  @override
  String get settingsHandednessLeft => 'Stângaci';

  @override
  String get settingsControlsTitle => 'Comenzi';

  @override
  String get settingsShakeToRollLabel => 'Scutură pentru a arunca zarurile';

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
  String get reorderPlayersHint =>
      'Trage un jucător de mâner pentru a schimba ordinea în jurul mesei.';

  @override
  String get reorderPlayerHandleLabel => 'Mută acest jucător';

  @override
  String get diceOffTitle => 'Cine începe?';

  @override
  String get diceOffInstructions =>
      'Toți aruncă zarul în același timp: începe cel mai mic. La egalitate, cei la egalitate aruncă din nou.';

  @override
  String diceOffTieBreak(String names) {
    return 'Egalitate: $names aruncă din nou.';
  }

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
  String get radarTargetsTooltip =>
      'Scoruri pe care mâna curentă le-ar putea tăia';

  @override
  String get radarGapTooltip => 'Diferența față de totalul mâinii curente';

  @override
  String get previousScoreHadTiretTooltip => 'Scorul anterior avea o liniuță';

  @override
  String get rankFirstTooltip => 'În frunte';

  @override
  String get rankSecondTooltip => 'Al 2-lea la scor';

  @override
  String get rankThirdTooltip => 'Al 3-lea la scor';

  @override
  String get rulesScreenTitle => 'Regulile jocului';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get tutorialSkip => 'Sari peste';

  @override
  String get tutorialFinalOutro =>
      'Botul e tăiat și trebuie acum să încerce el 10.000. Acum cunoști toate regulile: joc plăcut!';

  @override
  String get tutorialFinalExact => 'Trei de 4: fix 10.000! Se ia automat.';

  @override
  String get tutorialFinalNoStop =>
      '100: 9.600. În runda finală nu te poți opri: aruncă din nou.';

  @override
  String get tutorialFinalIntro =>
      'Botul a atins 10.000: e runda finală. Ca să câștigi trebuie să-l egalezi, ceea ce îl taie. Oprirea înainte e interzisă.';

  @override
  String get tutorialCollisionOutro =>
      'Botul e tăiat și revine la 1.500. Atingerea unei linii a altui jucător, chiar și veche, o taie și pe ea.';

  @override
  String get tutorialCollisionCollide =>
      'Doi de 1: 200. Ai ajunge la 2.000, scorul botului, cu roșu în radarul lui. Oprește-te ca să-l tai.';

  @override
  String get tutorialCollisionIntro =>
      'Pe linia botului, radarul arată scorurile lui pe care le-ai putea tăia: atingerea aceluiași total îl trimite înapoi.';

  @override
  String get tutorialInheritOutro =>
      'După un eșec, se pornește mereu cu 5 zaruri noi. O mână care n-ar mai putea fi încasată nu e propusă niciodată.';

  @override
  String get tutorialInheritStop => 'Un 1: mâna valorează 1.100. Oprește-te.';

  @override
  String get tutorialInheritTake =>
      'Botul s-a oprit la 1.000 lăsând 2 zaruri. Preia mâna: pornești de la cele 1.000 de puncte ale lui, iar cele 2 zaruri se aruncă imediat (se aruncă mereu cel puțin o dată înainte de oprire).';

  @override
  String get tutorialInheritIntro =>
      'Când un jucător se oprește lăsând zaruri, următorul le poate prelua, cu punctele lui ca bază.';

  @override
  String get tutorialExtensionOutro =>
      'Extensia ține toată tura, chiar și pentru un 5 (100 în loc de 50), și se șterge la zarurile fierbinți.';

  @override
  String get tutorialExtensionExtended =>
      'Un 2 singur nu valorează nimic… în afară de aici: după cei trei de 2, valorează 100 (cu roșu). Mâna face 300: oprește-te.';

  @override
  String get tutorialExtensionBrelan =>
      'Trei de 2: 200. Aruncă din nou ultimele 2 zaruri.';

  @override
  String get tutorialExtensionIntro =>
      'După trei la fel de o valoare, un zar singur de aceeași valoare, mai târziu în tură, valorează 100 de puncte.';

  @override
  String get tutorialBustOutro =>
      'Un eșec marchează linia cu o liniuță; al doilea o taie. La 0, un eșec nu costă nimic.';

  @override
  String get tutorialBustBarred =>
      'Al doilea eșec: linia de 1.500 e tăiată, revii la 500, scorul tău anterior. Apasă pe ✓.';

  @override
  String get tutorialBustRollAgain =>
      'Linia ta are o liniuță: un al doilea eșec ar tăia-o. Aruncă totuși.';

  @override
  String get tutorialBustTiret =>
      'Ai ars! Mâna e pierdută, iar linia ta de 1.500 primește o liniuță. Apasă pe ✓.';

  @override
  String get tutorialBustIntro =>
      'O aruncare fără puncte e un eșec: mâna curentă se pierde. Ai 1.500 de puncte.';

  @override
  String get tutorialHotDiceOutro =>
      'Reține: niciodată nu te oprești pe un total care se termină în 50, iar zarurile fierbinți se aruncă mereu din nou.';

  @override
  String get tutorialHotDiceStop =>
      '500: destul ca să intri, și fără 50 la final. Oprește-te.';

  @override
  String get tutorialHotDiceFives =>
      'Doi de 5, dar opționali: acest selector alege câți păstrezi. Cu amândoi, 550 s-ar termina în 50: nu te-ai putea opri. Alege 1.';

  @override
  String get tutorialHotDiceFullHand =>
      'Trei de 3: 300, mâna urcă la 450. Toate zarurile au contat: zaruri fierbinți! Butonul arată totalul pe care l-ai avea; se aruncă din nou toate 5, fără să te poți opri.';

  @override
  String get tutorialHotDiceKept =>
      'Zarurile 1 și 5 se păstrează: mâna valorează 150. Aruncă din nou celelalte 3 zaruri.';

  @override
  String get tutorialHotDiceIntro =>
      'Când toate zarurile aduc puncte, sunt zaruri fierbinți: se aruncă din nou toate 5. Iar un 5 singur e uneori opțional.';

  @override
  String get tutorialBasicsOutro =>
      '700 de puncte încasate: ești în joc! De acum, fiecare tură trebuie să aducă cel puțin 200 de puncte.';

  @override
  String get tutorialBasicsBrelan =>
      'Trei de 6: trei la fel valorează de 100 de ori valoarea lor, aici 600 (trei de 1: 1000). Mâna valorează 700, destul ca să intri: apasă pe mână ca să te oprești.';

  @override
  String get tutorialBasicsAce =>
      'Singure, aduc puncte doar 1 (100) și 5 (50): zarul de 1 e pus deoparte. Ca să intri în joc ai nevoie de 500 de puncte într-o tură: aruncă din nou celelalte 4 zaruri.';

  @override
  String get tutorialBasicsIntro =>
      'Bun venit în Le 10000! Scopul: să atingi exact 10.000 de puncte. La fiecare tură arunci 5 zaruri și pui deoparte pe cele care aduc puncte.';

  @override
  String get tutorialLessonFinalRound => 'Runda finală';

  @override
  String get tutorialLessonCollision => 'Tăierea unui jucător';

  @override
  String get tutorialLessonInheritedHand => 'Mâna moștenită';

  @override
  String get tutorialLessonExtension => 'Regula extensiei';

  @override
  String get tutorialLessonBust => 'Eșecul';

  @override
  String get tutorialLessonHotDice => 'Zaruri fierbinți';

  @override
  String get tutorialLessonBasics => 'Elementele de bază';

  @override
  String get tutorialBotTurn => 'Rândul botului: joacă singur.';

  @override
  String get tutorialRollPrompt => 'Apasă butonul de aruncare.';

  @override
  String get tutorialWholePath => 'Tot tutorialul';

  @override
  String get tutorialLessonsTitle => 'Lecțiile tutorialului';

  @override
  String get tutorialNextLesson => 'Lecția următoare';

  @override
  String tutorialLessonCounter(int number, int total, String title) {
    return 'Lecția $number/$total: $title';
  }

  @override
  String get tutorialPlayerName => 'Tu';

  @override
  String get tutorialNext => 'Înainte';

  @override
  String get tutorialFinish => 'Începe să joci';

  @override
  String get tutorialReplayButton => 'Lecțiile tutorialului';

  @override
  String get rulesGoalTitle => 'Scopul jocului';

  @override
  String get rulesGoalBody =>
      'Atinge exact 10.000 de puncte. Depășirea nu contează.';

  @override
  String get rulesTurnTitle => 'Cum se joacă o tură';

  @override
  String get rulesTurnBody =>
      'Arunci 5 zaruri, pui deoparte cel puțin un zar care aduce puncte, apoi arunci din nou restul sau te oprești și încasezi. Dacă o aruncare nu aduce nimic, este un eșec: pierzi tot ce ai acumulat în această tură.';

  @override
  String get rulesScoringTitle => 'Ce aduce puncte';

  @override
  String get rulesScoringBody =>
      '• Un 1 izolat: 100 de puncte. Un 5 izolat: 50 de puncte. Celelalte valori izolate (2, 3, 4, 6) nu aduc nimic.\n• Un brelan: valoarea zarului × 100 (trei de 6 valorează 600), cu excepția a trei de 1, care valorează 1000.\n• Un careu: cu 1000 de puncte mai mult decât brelanul corespunzător (patru de 6 valorează 1600, patru de 1 valorează 2000).\n• Cinci zaruri identice valorează valoarea zarului × 1000. Cinci de 1 aduc direct 10.000 de puncte: victoria imediată.\n• O suită de 5 zaruri consecutive (1-2-3-4-5 sau 2-3-4-5-6) valorează 500 de puncte.';

  @override
  String get rulesBustTitle => 'Eșec și tăiere';

  @override
  String get rulesBustBody =>
      'Un eșec pune o liniuță pe linia ta de scor curentă. Dacă avea deja una, linia este tăiată și scorul tău revine la valoarea anterioară. Dacă ajungi la același total ca alt jucător, acela este tăiat.';

  @override
  String get rulesEntryTitle => 'Oprirea';

  @override
  String get rulesEntryBody =>
      '• Ai nevoie de cel puțin 500 de puncte ca să intri în joc, apoi de cel puțin 200 pe tură.\n• Nu te poți opri niciodată pe un total de tură care se termină în 50 (250, 450…).\n• Dacă toate zarurile tale aduc puncte („zaruri fierbinți”), trebuie să arunci din nou toate cele 5.';

  @override
  String get rulesExtensionTitle => 'Regula extensiei';

  @override
  String get rulesExtensionBody =>
      'După ce ai încasat un brelan sau un careu, orice zar izolat de aceeași valoare mai târziu în tură valorează 100, inclusiv un 5. Dispare la zarurile fierbinți.';

  @override
  String get rulesInheritTitle => 'Moștenirea zarurilor jucătorului anterior';

  @override
  String get rulesInheritBody =>
      'Dacă te oprești cu zaruri nearuncate, jucătorul următor poate prelua acele zaruri și scorul tău ca bază sau poate relua cu 5 zaruri noi. După un eșec, reia întotdeauna cu 5 zaruri noi.';

  @override
  String get rulesVictoryTitle => 'Exact 10.000 și runda finală';

  @override
  String get rulesVictoryBody =>
      'De îndată ce o aruncare permite atingerea exactă a 10.000, luarea este automată și tura se încheie. Ceilalți jucători au atunci o ultimă tură ca să egaleze acel scor: în ea nimeni nu se poate opri sub 10.000, trebuie să-l egaleze sau să eșueze. Dacă și alt jucător ajunge la exact 10.000, îl taie pe primul și o nouă rundă finală începe în jurul lui.\nCaz particular: o mână plină care cade exact pe 10.000 este un eșec, fiindcă obligă la o nouă aruncare. Câștigă doar chinta de ași.';

  @override
  String get onlinePlayButton => 'Joacă online';

  @override
  String get onlineResumeButton => 'Reia jocul online';

  @override
  String get onlineTitle => 'Joc online';

  @override
  String get onlineCreateButton => 'Creează o cameră';

  @override
  String get onlineJoinButton => 'Intră';

  @override
  String get onlineCodeLabel => 'Codul camerei';

  @override
  String get onlineOrDivider => 'sau';

  @override
  String get onlineShareHint =>
      'Dă acest cod celorlalți jucători ca să se alăture ție.';

  @override
  String get onlineShareButton => 'Distribuie codul';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Alătură-te partidei mele online de Le 10000! Codul camerei: $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Jucători ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Gazdă';

  @override
  String get onlineDisconnectedBadge => 'Deconectat';

  @override
  String get onlineNeedTwoPlayers =>
      'Sunt necesari cel puțin 2 jucători, toți conectați.';

  @override
  String get onlineWaitingForHost => 'Se așteaptă ca gazda să înceapă…';

  @override
  String get onlineLeaveButton => 'Ieși';

  @override
  String get onlineLeaveConfirmTitle => 'Ieși din jocul online?';

  @override
  String get onlineLeaveConfirmBody =>
      'Într-un joc început, locul tău rămâne gol, iar jocul așteaptă întoarcerea ta.';

  @override
  String get onlineLeaveGameBody =>
      'Părăsești camera: un bot va juca în locul tău până la finalul jocului.';

  @override
  String get onlineDiceOffWaitingStart => 'Se așteaptă începerea jocului';

  @override
  String get logPlayerReplacedByBot =>
      'a părăsit jocul: un bot joacă în locul său';

  @override
  String get botSeatTooltip => 'Jucat de un bot (jucător plecat)';

  @override
  String get rematchButton => 'Joacă din nou';

  @override
  String rematchProposal(String name) {
    return '$name propune o revanșă';
  }

  @override
  String get rematchWaiting => 'Se așteaptă ceilalți jucători…';

  @override
  String rematchSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get rematchAccept => 'Acceptă';

  @override
  String get rematchRefuse => 'Refuză';

  @override
  String get rematchExcludedNotice =>
      'Ai părăsit camera: nu e revanșă pentru tine.';

  @override
  String get rematchCancelledNotice =>
      'Nu e revanșă: e nevoie de cel puțin doi jucători.';

  @override
  String get onlineConnecting => 'Conectare la server…';

  @override
  String get onlineReconnecting => 'Conexiune pierdută, se reconectează…';

  @override
  String get onlineSuspended =>
      'Joc suspendat: un jucător lipsește de prea mult timp.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName joacă…';
  }

  @override
  String get onlineDiceOffContinue => 'Joacă';

  @override
  String get onlineErrorUnreachable => 'Serverul nu poate fi contactat.';

  @override
  String get onlineErrorRoomNotFound => 'Nicio cameră cu acest cod.';

  @override
  String get onlineErrorRoomFull => 'Această cameră este plină.';

  @override
  String get onlineErrorGameStarted => 'Acest joc a început deja.';

  @override
  String get onlineErrorRateLimited =>
      'Prea multe încercări: încearcă din nou peste puțin timp.';

  @override
  String get onlineErrorBadToken =>
      'Locul tău în această cameră nu mai există.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Actualizează aplicația pentru a juca online.';

  @override
  String get onlineErrorGeneric => 'A apărut o eroare.';

  @override
  String get myProfileTitle => 'Profilul meu';

  @override
  String get myProfileWelcomeTitle => 'Bine ai venit!';

  @override
  String get myProfileWelcomeMessage =>
      'Creează-ți profilul: numele tău, o poreclă dacă vrei și mâna cu care joci. Online, ceilalți jucători îți vor vedea porecla sau numele, dacă nu ai poreclă.';

  @override
  String get myProfileExistingPrompt =>
      'Ești deja în lista de jucători? Atinge-ți numele.';

  @override
  String get myProfileCreateButton => 'Creează-mi profilul';

  @override
  String get myProfileEditButton => 'Modifică-mi profilul';

  @override
  String get myProfileBadge => 'Eu';

  @override
  String onlinePlayingAs(String name) {
    return 'Joci ca „$name”';
  }

  @override
  String get onlineNameInvalidError =>
      'Online, porecla (sau numele) ta trebuie să aibă cel mult 20 de caractere, fără caractere invizibile.';

  @override
  String get settingsDiceSoundLabel => 'Sunetul zarurilor';

  @override
  String get settingsDiceSoundRealistic => 'Realist';

  @override
  String get settingsDiceSoundSynthetic => 'Sintetic';

  @override
  String get homeChipsHint => 'Ține apăsat pe o fisă ca să-i vezi numele.';

  @override
  String get emoteThoughtful => 'Gânditor';

  @override
  String get emoteMocking => 'Mort de râs';

  @override
  String get emoteDevastated => 'Devastat';

  @override
  String get emoteJoyful => 'Îmbrățișare';

  @override
  String get emotePhraseCoincidence => 'Ce coincidență...';

  @override
  String get emotePhraseStickyFive => 'Un cinci lipicios!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Mână plină, mână goală!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Un 1000 nu se reia niciodată!';

  @override
  String get emotePhraseNoWay => 'Pur și simplu imposibil!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Salut!';

  @override
  String get emotePhraseYes => 'Da!';

  @override
  String get emotePhraseTooGreedy => 'Lăcomia e un defect urât!';

  @override
  String get emotePhraseTooLucky => 'Cam prea mult noroc...';

  @override
  String get emotePhraseDryTenThousand => 'Direct la 10000';

  @override
  String get emotePhraseLucky => 'Norocosule!';

  @override
  String get emotePhraseGoodLuck => 'Baftă!';

  @override
  String get emotePhraseThanks => 'Mulțumesc';

  @override
  String get emotePhraseSorryMustGo => 'Scuze, dar trebuie să plec';

  @override
  String get emoteAngry => 'Supărat';

  @override
  String get emoteRelieved => 'Ușurat';

  @override
  String get emotePhraseStrangeChoice =>
      'Dar ce alegere ciudată mai e și asta?';

  @override
  String get emotePhraseAllByFives => 'Totul pe cinci!';

  @override
  String get emotePhraseWithPanache => 'Cu panaș!';

  @override
  String get emotePhraseUnfair => 'E chiar prea nedrept';

  @override
  String get emotePhrasePhew => 'Uf!';

  @override
  String get emotePhraseAtLast => 'În sfârșit!';

  @override
  String get emotePhraseCloseCall => 'A fost cât pe ce!';

  @override
  String get emotePhraseWellPlayed => 'Bine jucat';

  @override
  String get emotePhraseSorry => 'Scuze';

  @override
  String get gameHistoryBar => 'Istoric';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'Este disponibilă o versiune nouă ($version, build $build).';
  }

  @override
  String get updateNowButton => 'Actualizează';

  @override
  String get updateLaterButton => 'Mai târziu';
}
