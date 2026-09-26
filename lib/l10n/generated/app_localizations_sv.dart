// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get splashPresents => 'presenterar';

  @override
  String get validateButton => 'Bekräfta';

  @override
  String get settingsTooltip => 'Inställningar';

  @override
  String get helpTooltip => 'Spelregler';

  @override
  String get aboutTooltip => 'Om';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Stäng';

  @override
  String playersCountTitle(int count) {
    return 'Spelare ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Starta spelet';

  @override
  String get newGameSectionLabel => 'Ny run...';

  @override
  String get resumeGamesButton => 'Återuppta spel';

  @override
  String get managePlayersButton => 'Hantera spelare';

  @override
  String get finishedGamesButton => 'Senast avslutade spel';

  @override
  String get statisticsButton => 'Statistik';

  @override
  String playersScreenTitle(int count) {
    return 'Spelare ($count)';
  }

  @override
  String get addPlayerTooltip => 'Lägg till en spelare';

  @override
  String get noPlayersMessage => 'Inga sparade spelare än.';

  @override
  String get newPlayerTitle => 'Ny spelare';

  @override
  String get editPlayerTitle => 'Redigera spelare';

  @override
  String get playerNameLabel => 'Namn';

  @override
  String get playerNicknameLabel => 'Smeknamn (valfritt)';

  @override
  String get playerNameRequiredError => 'Namn krävs.';

  @override
  String get playerNameTakenError =>
      'Det här namnet används redan av en annan spelare.';

  @override
  String get deletePlayerConfirmTitle => 'Radera den här spelaren?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Profilen för ”$name” och dess statistik raderas permanent. Redan spelade spel behålls.';
  }

  @override
  String get statsSectionTime => 'Speltid';

  @override
  String get statsSectionGames => 'Spel';

  @override
  String get statsSectionFigures => 'Kombinationer';

  @override
  String get statsSectionRolls => 'Rundor och kast';

  @override
  String get statsTurns => 'Spelade rundor';

  @override
  String get statsRolls => 'Kast';

  @override
  String get statsRollsPerTurn => 'Kast per runda';

  @override
  String get statsSectionMisc => 'Bragder';

  @override
  String get statsTotalTime => 'Totalt';

  @override
  String get statsAverageTime => 'Snitt per spel';

  @override
  String get statsShortestTime => 'Kortaste';

  @override
  String get statsLongestTime => 'Längsta';

  @override
  String get statsGamesPlayed => 'Spelade';

  @override
  String get statsGamesWon => 'Vunna';

  @override
  String get statsGamesLost => 'Förlorade';

  @override
  String get statsLoneAces => 'Enstaka ettor behållna';

  @override
  String get statsLoneFives => 'Enstaka femmor behållna';

  @override
  String get statsBrelans => 'Tretal';

  @override
  String get statsCarres => 'Fyrtal';

  @override
  String get statsQuintes => 'Femtal';

  @override
  String get statsSuites => 'Stegar';

  @override
  String get statsSmallSuites => 'varav små';

  @override
  String get statsBigSuites => 'varav stora';

  @override
  String get statsAceQuints => 'Fem ettor';

  @override
  String get statsAceQuintsWon => 'varav vinnande';

  @override
  String get statsBestTurn => 'Bästa runda';

  @override
  String get statsHotDiceRun => 'Heta tärningar i rad';

  @override
  String get statsBusts => 'Bom';

  @override
  String get statsLongestBustStreak => 'längsta svit';

  @override
  String get statsSelfBars => 'Struket själv';

  @override
  String get statsBarsInflicted => 'Struket för andra';

  @override
  String get scoreChartTitle => 'Poängutveckling';

  @override
  String get gameStatsTitle => 'Spelstatistik';

  @override
  String get gameStatsGameSection => 'Spel';

  @override
  String get gameStatsFiguresSection => 'Kombinationer i spelet';

  @override
  String get gameStatsDuration => 'Speltid';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns rundor',
      one: '$turns runda',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts bom',
      one: '$busts bom',
    );
    return '$_temp0 · bästa $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games spel',
      one: '$games spel',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won vunna',
      one: '$won vunnet',
    );
    return '$_temp0 · $_temp1 · bästa $best';
  }

  @override
  String get scoreChartEmpty =>
      'Ingen runda är avslutad än: det finns inget att rita.';

  @override
  String get replayUnavailable =>
      'Det här spelet kan inte spelas upp igen: dess logg är ofullständig.';

  @override
  String get replayPlay => 'Spela upp';

  @override
  String get replayPause => 'Paus';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Runda $turn';
  }

  @override
  String get scoreChartXAxis => 'Spelade rundor';

  @override
  String get statsBreakdownRow => 'varav';

  @override
  String get statsRecordsTitle => 'Rekord';

  @override
  String get statsNoRecordYet => 'Inga rekord än.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Välj spelare';

  @override
  String get addHumanTooltip => 'Lägg till en spelare';

  @override
  String get addBotTooltip => 'Lägg till en bot';

  @override
  String get createPlayerButton => 'Ny spelare';

  @override
  String get noPlayersToPickMessage =>
      'Inga sparade spelare. Skapa en för att börja.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Ta bort från spelet';

  @override
  String get notEnoughPlayersMessage => 'Minst två spelare behövs.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spelade spel',
      one: '$count spelat spel',
      zero: 'Inga spelade spel',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Avbrutna runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Avslutade runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Inga pausade spel än.';

  @override
  String get noFinishedRunsMessage => 'Inga avslutade runs än.';

  @override
  String get gameRunParticipantsSeparator => ' mot ';

  @override
  String get deleteGameConfirmTitle => 'Radera det här spelet?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Spelet ”$alias” kommer att raderas permanent.';
  }

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get deleteButton => 'Radera';

  @override
  String get resumeLastGameDialogTitle => 'Återuppta spelet?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Spelet ”$alias” pågår. Vill du återuppta det?';
  }

  @override
  String get resumeGameButton => 'Återuppta';

  @override
  String get gameOverReplayButton => 'Se spelet igen';

  @override
  String get scoreGridLabel => 'Poängtabell';

  @override
  String get finalRoundBanner => 'Sista rundan: en spelare har nått 10000!';

  @override
  String get currentRollZoneLabel => 'Bana';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Bana ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Aktuell hand';

  @override
  String get logHotDiceMessage => 'Heta tärningar!';

  @override
  String get logScoreCollisionMessage => 'Poäng struken:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return '$kept: $gain, $_temp0 => $total p';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, heta tärningar => $total p';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score p noterade => $total p';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score p övertagna';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Bom! => $score streck';
  }

  @override
  String get logBustBarredPrefix => 'Bom! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'tillbaka till $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Att ta över denna hand skulle redan överskrida 10000: kan inte stanna.';

  @override
  String get rollButton => 'Kasta';

  @override
  String get showProbabilitiesSetting => 'Visa sannolikheter';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Visar på knappen ”Kasta” chansen att få minst en poäng';

  @override
  String get stopButton => 'Stanna';

  @override
  String get bustedTitle => 'Bom!';

  @override
  String get bustExceedsTarget => 'Detta kast skulle överskrida 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Heta tärningar på 10000: du kan inte stanna, och att kasta om allt skulle gå över.';

  @override
  String get bustContinueButton => 'Fortsätt';

  @override
  String get inheritedHandDialogTitle => 'Ta över?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tärningar',
      one: '$count tärning',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Ta över handen';

  @override
  String get newHandButton => 'Ny hand';

  @override
  String get failureBelowMinimum => 'För lågt poäng för att stanna.';

  @override
  String get failureEndsIn50 =>
      'Du kan inte stanna på ett poäng som slutar på 50.';

  @override
  String get failureMustContinueHotDice => 'Du måste kasta igen.';

  @override
  String get failureNotRolledYet =>
      'Du måste kasta tärningarna innan du kan stanna.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Att stanna nu skulle göra det omöjligt att nå exakt 10000.';

  @override
  String get settingsMainPlayerTitle => 'Huvudspelare';

  @override
  String get settingsYourNameLabel => 'Ditt namn (enhetens ägare)';

  @override
  String get settingsDelaysTitle => 'Fördröjningar';

  @override
  String get settingsDelaysDescription =>
      'Fördröjning innan en automatisk åtgärd utlöses av sig själv. 0 för att inaktivera.';

  @override
  String get settingsAiDelayLabel => 'AI-meddelanden (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatiska åtgärder för den mänskliga spelaren (ms)';

  @override
  String get settingsDiceTitle => 'Tärningar';

  @override
  String get settingsDiceUniform => 'Enfärgad';

  @override
  String get settingsDiceVaried => 'Blandad';

  @override
  String get settingsSoundsTitle => 'Ljud';

  @override
  String get settingsMusicLabel => 'Bakgrundsmusik';

  @override
  String get settingsSoundEffectsLabel => 'Ljudeffekter';

  @override
  String get settingsHandednessLabel => 'Placering av knappar';

  @override
  String get settingsHandednessRight => 'Högerhänt';

  @override
  String get settingsHandednessLeft => 'Vänsterhänt';

  @override
  String get settingsControlsTitle => 'Kontroller';

  @override
  String get settingsShakeToRollLabel => 'Skaka för att kasta tärningarna';

  @override
  String get settingsPausedGamesTitle => 'Pausade spel';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Bekräfta innan ett spel raderas';

  @override
  String get settingsLanguageTitle => 'Språk';

  @override
  String get settingsLanguageSystemOption => 'Telefonens språk';

  @override
  String get reorderPlayersHint =>
      'Dra en spelare i handtaget för att ändra ordningen runt bordet.';

  @override
  String get reorderPlayerHandleLabel => 'Flytta den här spelaren';

  @override
  String get diceOffTitle => 'Vem börjar?';

  @override
  String get diceOffInstructions =>
      'Alla slår sin tärning samtidigt: den lägsta börjar. Vid lika slår de som står lika om.';

  @override
  String diceOffTieBreak(String names) {
    return 'Oavgjort: $names kastar igen.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName börjar spelet!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Spelordning';

  @override
  String get diceOffReversedNote =>
      'Duell mellan grannar vunnen av den andra: spelet går åt andra hållet.';

  @override
  String get gameOverTitle => 'Spelet är slut';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vinner!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Lämna över enheten till';

  @override
  String get readyButton => 'Klar';

  @override
  String get notEnteredLabel => '(inte inne än)';

  @override
  String get opportunityTooltip =>
      '200 poäng från att stryka spelaren precis ovanför!';

  @override
  String get dangerTooltip =>
      'Fara: spelaren precis under är bara 200 poäng bort, risk att du blir struken';

  @override
  String get tiretTooltip => 'Streck: ett andra bom kommer att stryka poängen';

  @override
  String get previousScoreHadTiretTooltip => 'Föregående poäng hade ett streck';

  @override
  String get rankFirstTooltip => 'I ledningen';

  @override
  String get rankSecondTooltip => '2:a på poäng';

  @override
  String get rankThirdTooltip => '3:e på poäng';

  @override
  String get rulesScreenTitle => 'Spelregler';

  @override
  String get rulesGoalTitle => 'Spelets mål';

  @override
  String get rulesGoalBody =>
      'Den första spelaren som når exakt 10 000 poäng vinner spelet. Du måste pricka talet exakt: att gå över räknas inte.';

  @override
  String get rulesTurnTitle => 'Så spelas en runda';

  @override
  String get rulesTurnBody =>
      'På din tur kastar du 5 tärningar. Vissa värden ger poäng (se nedan), andra ger ingenting. Du lägger undan minst en tärning som ger poäng och väljer sedan: kasta om de återstående tärningarna för att försöka samla fler poäng, eller stanna och notera det du samlat den här rundan. Om ett kast inte ger en enda poäng är det bom (se nedan) och du förlorar allt du samlat den här rundan.';

  @override
  String get rulesScoringTitle => 'Vad som ger poäng';

  @override
  String get rulesScoringBody =>
      '• En enstaka etta: 100 poäng. En enstaka femma: 50 poäng. Övriga enstaka värden (2, 3, 4, 6) ger ingenting.\n• Tre likadana tärningar: 1000 poäng för tre ettor, annars tärningens värde × 100 (tre fyror är värda 400, tre sexor 600).\n• En fjärde tärning med samma värde ger ytterligare 1000 poäng.\n• Fem likadana tärningar är värda tärningens värde × 1000, utom fem ettor, som ger 10 000 poäng direkt: omedelbar seger.\n• En stege med 5 tärningar i följd (1-2-3-4-5 eller 2-3-4-5-6) är värd 500 poäng.';

  @override
  String get rulesHotDiceTitle => 'Heta tärningar: en tvingad andra chans';

  @override
  String get rulesHotDiceBody =>
      'Om alla tärningar du just kastade ger poäng måste du kasta om alla 5 tärningarna: du kan inte stanna just då. Det kallas ”heta tärningar”.';

  @override
  String get rulesBustTitle => 'Bom';

  @override
  String get rulesBustBody =>
      'Om ett kast inte ger några poäng alls slutar din runda omedelbart och du förlorar alla poäng du samlat den här rundan (det du noterat i tidigare rundor behåller du). En bom markerar också din aktuella poängrad med ett streck; hade den redan ett stryks den, och din poäng faller tillbaka till föregående värde.';

  @override
  String get rulesEntryTitle => 'Att komma in i spelet';

  @override
  String get rulesEntryBody =>
      'För att börja få poäng måste din allra första lyckade runda ge minst 500 poäng. När du väl är inne i spelet måste varje följande runda ge minst 200 poäng för att du ska få stanna.';

  @override
  String get rulesNoFiftyTitle => 'Aldrig en poäng som slutar på 50';

  @override
  String get rulesNoFiftyBody =>
      'Du får aldrig välja att stanna frivilligt på en rundsumma som slutar på 50 (som 250 eller 450): du måste kasta om tills du får en giltig summa.';

  @override
  String get rulesExtensionTitle => 'Utvidgningsregeln';

  @override
  String get rulesExtensionBody =>
      'När du har noterat ett tretal eller fyrtal av ett visst värde (till exempel tre fyror) är varje enstaka tärning med samma värde som kommer senare i samma runda värd 100 poäng i stället för sitt vanliga värde — även en enstaka femma, som då är värd 100 i stället för 50. Fördelen försvinner så snart du får heta tärningar.';

  @override
  String get rulesInheritTitle => 'Ärva föregående spelares tärningar';

  @override
  String get rulesInheritBody =>
      'När en spelare stannar frivilligt med tärningar kvar att kasta kan nästa spelare välja att ta över de återstående tärningarna tillsammans med den redan samlade poängen som utgångspunkt, eller börja om från noll med 5 nya tärningar. Efter en bom börjar nästa spelare däremot alltid med 5 nya tärningar, utan att ärva något.';

  @override
  String get rulesBarredTitle => 'Streck och struken';

  @override
  String get rulesBarredBody =>
      'En bom sätter ett varningsstreck på din aktuella poängrad om den inte redan har ett. Har den redan ett stryks raden, och din poäng faller tillbaka till föregående värde. Om din poäng blir exakt lika med en annan spelares stryks den spelaren på samma sätt, oavsett om hen redan hade ett streck eller inte.';

  @override
  String get rulesVictoryTitle => 'Så vinner du';

  @override
  String get rulesVictoryBody =>
      'Den första spelaren som når exakt 10 000 poäng utlöser en slutrunda: varje annan spelare får en sista chans på sin tur att komma ikapp eller gå förbi. Om en annan spelare också når exakt 10 000 under slutrundan tar hen över kronan och en ny slutrunda börjar runt hen.';

  @override
  String get onlinePlayButton => 'Spela online';

  @override
  String get onlineResumeButton => 'Återuppta onlinespelet';

  @override
  String get onlineTitle => 'Onlinespel';

  @override
  String get onlineNameLabel => 'Ditt smeknamn';

  @override
  String get onlineCreateButton => 'Skapa ett rum';

  @override
  String get onlineJoinButton => 'Gå med';

  @override
  String get onlineCodeLabel => 'Rumskod';

  @override
  String get onlineOrDivider => 'eller';

  @override
  String get onlineShareHint =>
      'Ge den här koden till de andra spelarna så att de kan gå med.';

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Spelare ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Värd';

  @override
  String get onlineDisconnectedBadge => 'Frånkopplad';

  @override
  String get onlineNeedTwoPlayers => 'Minst 2 spelare krävs, alla anslutna.';

  @override
  String get onlineWaitingForHost => 'Väntar på att värden ska starta…';

  @override
  String get onlineLeaveButton => 'Lämna';

  @override
  String get onlineLeaveConfirmTitle => 'Lämna onlinespelet?';

  @override
  String get onlineLeaveConfirmBody =>
      'I ett påbörjat spel förblir din plats tom och spelet väntar på att du kommer tillbaka.';

  @override
  String get onlineConnecting => 'Ansluter till servern…';

  @override
  String get onlineReconnecting => 'Anslutningen bröts, återansluter…';

  @override
  String get onlineSuspended =>
      'Spelet pausat: en spelare har varit borta för länge.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName spelar…';
  }

  @override
  String get onlineDiceOffContinue => 'Spela';

  @override
  String get onlineErrorUnreachable => 'Servern går inte att nå.';

  @override
  String get onlineErrorRoomNotFound => 'Inget rum med den här koden.';

  @override
  String get onlineErrorRoomFull => 'Det här rummet är fullt.';

  @override
  String get onlineErrorGameStarted => 'Det här spelet har redan börjat.';

  @override
  String get onlineErrorRateLimited =>
      'För många försök: försök igen om en stund.';

  @override
  String get onlineErrorBadToken =>
      'Din plats i det här rummet finns inte längre.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Uppdatera appen för att spela online.';

  @override
  String get onlineErrorGeneric => 'Något gick fel.';
}
