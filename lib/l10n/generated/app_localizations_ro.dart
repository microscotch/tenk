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
  String logBustTiretMessage(int score) {
    return 'Ai ars! => $score liniuță';
  }

  @override
  String get logBustBarredPrefix => 'Ai ars! =>';

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
  String get diceOffPlayOrderLabel => 'Ordinea de joc';

  @override
  String get diceOffReversedNote =>
      'Duel între vecini câștigat de al doilea: jocul se desfășoară în sens invers.';

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
  String get rulesGoalTitle => 'Scopul jocului';

  @override
  String get rulesGoalBody =>
      'Primul jucător care ajunge la exact 10.000 de puncte câștigă jocul. Trebuie să nimerești exact acest număr: depășirea nu contează.';

  @override
  String get rulesTurnTitle => 'Cum se joacă o tură';

  @override
  String get rulesTurnBody =>
      'La tura ta, arunci 5 zaruri. Unele valori aduc puncte (vezi mai jos), altele nu valorează nimic. Pui deoparte cel puțin un zar care punctează, apoi alegi: arunci din nou zarurile rămase ca să aduni mai multe puncte, sau te oprești și încasezi ce ai acumulat în această tură. Dacă o aruncare nu aduce niciun punct, ai ars (vezi mai jos) și pierzi tot ce acumulaseși în această tură.';

  @override
  String get rulesScoringTitle => 'Ce aduce puncte';

  @override
  String get rulesScoringBody =>
      '• Un 1 izolat: 100 de puncte. Un 5 izolat: 50 de puncte. Celelalte valori izolate (2, 3, 4, 6) nu aduc nimic.\n• Trei zaruri identice: 1000 de puncte pentru trei de 1, altfel valoarea zarului × 100 (trei de 4 valorează 400, trei de 6 valorează 600).\n• Un al patrulea zar cu aceeași valoare adaugă încă 1000 de puncte.\n• Cinci zaruri identice valorează valoarea zarului × 1000, cu excepția a cinci de 1, care aduc direct 10.000 de puncte: victoria imediată.\n• O suită de 5 zaruri consecutive (1-2-3-4-5 sau 2-3-4-5-6) valorează 500 de puncte.';

  @override
  String get rulesHotDiceTitle =>
      'Zaruri fierbinți: o a doua șansă obligatorie';

  @override
  String get rulesHotDiceBody =>
      'Dacă toate zarurile pe care tocmai le-ai aruncat aduc puncte, trebuie să arunci din nou toate cele 5 zaruri: nu te poți opri exact în acel moment. Asta se numește „zaruri fierbinți”.';

  @override
  String get rulesBustTitle => 'Eșecul';

  @override
  String get rulesBustBody =>
      'Dacă o aruncare nu aduce absolut niciun punct, tura ta se încheie imediat și pierzi toate punctele acumulate în această tură (ce ai încasat în turele anterioare rămâne câștigat). Un eșec marchează totodată linia ta de scor curentă cu o liniuță; dacă avea deja una, e tăiată și scorul tău revine la valoarea anterioară.';

  @override
  String get rulesEntryTitle => 'Intrarea în joc';

  @override
  String get rulesEntryBody =>
      'Ca să începi să marchezi, prima ta tură reușită trebuie să aducă cel puțin 500 de puncte. Odată intrat în joc, fiecare tură următoare trebuie să aducă cel puțin 200 de puncte ca să te poți opri.';

  @override
  String get rulesNoFiftyTitle => 'Niciodată un scor terminat în 50';

  @override
  String get rulesNoFiftyBody =>
      'Nu poți alege niciodată să te oprești de bunăvoie la un total de tură terminat în 50 (de exemplu 250 sau 450): trebuie să arunci din nou până obții un total valid.';

  @override
  String get rulesExtensionTitle => 'Regula extensiei';

  @override
  String get rulesExtensionBody =>
      'Odată ce ai încasat o tripletă sau un careu de o anumită valoare (de exemplu trei de 4), orice zar izolat cu aceeași valoare obținut mai târziu în aceeași tură aduce 100 de puncte în loc de valoarea obișnuită — inclusiv un 5 izolat, care valorează atunci 100 în loc de 50. Acest avantaj dispare de îndată ce obții zaruri fierbinți.';

  @override
  String get rulesInheritTitle => 'Moștenirea zarurilor jucătorului anterior';

  @override
  String get rulesInheritBody =>
      'Când un jucător se oprește de bunăvoie având încă zaruri nearuncate, jucătorul următor poate alege să preia zarurile rămase împreună cu scorul deja acumulat ca bază de pornire, sau să reînceapă de la zero cu 5 zaruri noi. După un eșec, în schimb, jucătorul următor pornește întotdeauna cu 5 zaruri noi, fără să moștenească nimic.';

  @override
  String get rulesBarredTitle => 'Liniuță și tăiat';

  @override
  String get rulesBarredBody =>
      'Un eșec pune o liniuță de avertizare pe linia ta de scor curentă, dacă nu are deja una. Dacă are deja una, linia e tăiată și scorul tău revine la valoarea anterioară. Dacă scorul tău ajunge exact la același total ca al altui jucător, acesta e tăiat în același fel, fie că avea deja o liniuță, fie că nu.';

  @override
  String get rulesVictoryTitle => 'Cum câștigi';

  @override
  String get rulesVictoryBody =>
      'Primul jucător care ajunge la exact 10.000 de puncte declanșează o rundă finală: fiecare dintre ceilalți jucători are o ultimă șansă să-l egaleze sau să-l depășească la tura sa. Dacă în această rundă finală și alt jucător ajunge la exact 10.000, el preia coroana și o nouă rundă finală începe în jurul lui.';

  @override
  String get onlinePlayButton => 'Joacă online';

  @override
  String get onlineResumeButton => 'Reia jocul online';

  @override
  String get onlineTitle => 'Joc online';

  @override
  String get onlineNameLabel => 'Porecla ta';

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
}
