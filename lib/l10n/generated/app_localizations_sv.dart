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
  String get failureMustContinueFinalRound =>
      'Du kan inte stanna: sista rundan kräver att du når exakt 10000.';

  @override
  String get failureNotRolledYet =>
      'Du måste kasta tärningarna innan du kan stanna.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Att stanna nu skulle göra det omöjligt att nå exakt 10000.';

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
  String get tutorialTitle => 'Handledning';

  @override
  String get tutorialSkip => 'Hoppa över';

  @override
  String get tutorialNext => 'Nästa';

  @override
  String get tutorialRoll => 'Kasta tärningarna';

  @override
  String get tutorialKeep => 'Behåll';

  @override
  String get tutorialFinish => 'Börja spela';

  @override
  String get tutorialReplayButton => 'Se handledningen igen';

  @override
  String get tutorialStep0 =>
      'Välkommen till Le 10000! Målet: nå exakt 10 000 poäng. Vi spelar en runda tillsammans; inget du gör här sparas.';

  @override
  String get tutorialStep1 =>
      'På din tur kastar du 5 tärningar. Tryck på ”Kasta tärningarna”.';

  @override
  String get tutorialStep2 =>
      'Bara ettan (100 poäng) och femman (50 poäng) ger poäng här. Ettan är obligatorisk; femman kunde läggas undan, men vi behåller den. Tryck på ”Behåll”.';

  @override
  String get tutorialStep3 =>
      'Den aktuella handen är värd 150 poäng och 3 tärningar återstår att kasta om. För att komma in i spelet behövs minst 500 poäng: vi kastar om.';

  @override
  String get tutorialStep4 =>
      'Tre likadana tärningar: tre treor är värda 300 poäng. Behåll dem.';

  @override
  String get tutorialStep5 =>
      'Alla tärningar gav poäng: heta tärningar! Du måste kasta om alla 5 och kan inte stanna. Den aktuella handen behåller sina 450 poäng.';

  @override
  String get tutorialStep6 =>
      'Två ettor och en femma: 250 till, alltså 700. Det lönar sig att behålla femman: att stanna på 650 är förbjudet (aldrig en summa som slutar på 50).';

  @override
  String get tutorialStep7 =>
      '700 poäng: över 500 och ingen 50 på slutet. Du kan stanna och bokföra dem. Tryck på ”Stanna”.';

  @override
  String get tutorialStep8 =>
      '700 poäng bokförda! Nu ser vi vad som händer när tärningarna inte ger något: kasta.';

  @override
  String get tutorialStep9 =>
      'Ingen tärning ger poäng: en bom! Rundan är förlorad och ett streck markerar din poängrad; en andra bom skulle stryka den. Den första som når exakt 10 000 utlöser en slutrunda för de andra. De fullständiga reglerna finns i menyn. Ha så roligt!';

  @override
  String get rulesGoalTitle => 'Spelets mål';

  @override
  String get rulesGoalBody => 'Nå exakt 10 000 poäng. Att gå över räknas inte.';

  @override
  String get rulesTurnTitle => 'Så spelas en runda';

  @override
  String get rulesTurnBody =>
      'Du kastar 5 tärningar, lägger undan minst en tärning som ger poäng och kastar sedan resten igen eller stannar och bokför. Om ett kast inte ger något är det en bom: du förlorar allt du samlat den här rundan.';

  @override
  String get rulesScoringTitle => 'Vad som ger poäng';

  @override
  String get rulesScoringBody =>
      '• En enstaka etta: 100 poäng. En enstaka femma: 50 poäng. Övriga enstaka värden (2, 3, 4, 6) ger ingenting.\n• Tre likadana: tärningens värde × 100 (tre sexor är värda 600), utom tre ettor: 1000.\n• Fyra likadana: 1000 poäng mer än motsvarande tre likadana (fyra sexor är värda 1600, fyra ettor 2000).\n• Fem likadana är värda tärningens värde × 1000. Fem ettor ger 10 000 poäng direkt: omedelbar seger.\n• En stege med 5 tärningar i följd (1-2-3-4-5 eller 2-3-4-5-6) är värd 500 poäng.';

  @override
  String get rulesBustTitle => 'Bom och struket';

  @override
  String get rulesBustBody =>
      'En bom sätter ett streck på din aktuella poängrad. Hade den redan ett stryks den och du faller tillbaka till föregående värde. Om du når samma summa som en annan spelare stryks hen.';

  @override
  String get rulesEntryTitle => 'Att stanna';

  @override
  String get rulesEntryBody =>
      '• Du behöver minst 500 poäng för att komma in i spelet, därefter minst 200 per runda.\n• Du kan aldrig stanna på en rundsumma som slutar på 50 (250, 450…).\n• Om alla dina tärningar ger poäng (”heta tärningar”) måste du kasta om alla 5.';

  @override
  String get rulesExtensionTitle => 'Utvidgningsregeln';

  @override
  String get rulesExtensionBody =>
      'När du har bokfört tre eller fyra likadana är varje enstaka tärning med samma värde senare i rundan värd 100, även en femma. Det försvinner vid heta tärningar.';

  @override
  String get rulesInheritTitle => 'Ärva föregående spelares tärningar';

  @override
  String get rulesInheritBody =>
      'Om du stannar med tärningar som inte kastats kan nästa spelare ta över dem och din poäng som bas, eller börja med 5 nya tärningar. Efter en bom börjar hen alltid med 5 nya tärningar.';

  @override
  String get rulesVictoryTitle => 'Exakt 10 000 och slutrunda';

  @override
  String get rulesVictoryBody =>
      'Så snart ett kast gör det möjligt att nå exakt 10 000 sker det automatiskt och rundan stannar. De andra spelarna får då en sista runda för att komma ikapp: i den får ingen stanna under 10 000, man måste jämna ut eller bomma. Om en annan spelare också når exakt 10 000 stryker hen den första och en ny slutrunda börjar runt hen.\nSpecialfall: En full hand som landar exakt på 10 000 är en bom, eftersom den tvingar till nytt kast. Bara ess-femmaren vinner.';

  @override
  String get onlinePlayButton => 'Spela online';

  @override
  String get onlineResumeButton => 'Återuppta onlinespelet';

  @override
  String get onlineTitle => 'Onlinespel';

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
  String get onlineShareButton => 'Dela koden';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Häng med i mitt onlinespel av Le 10000! Rumskod: $code\n$link';
  }

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

  @override
  String get myProfileTitle => 'Min profil';

  @override
  String get myProfileWelcomeTitle => 'Välkommen!';

  @override
  String get myProfileWelcomeMessage =>
      'Skapa din profil: ditt namn, ett smeknamn om du vill och handen du spelar med. Online ser de andra spelarna ditt smeknamn, eller ditt namn om du inte har något.';

  @override
  String get myProfileExistingPrompt =>
      'Finns du redan i spelarlistan? Tryck på ditt namn.';

  @override
  String get myProfileCreateButton => 'Skapa min profil';

  @override
  String get myProfileEditButton => 'Redigera min profil';

  @override
  String get myProfileBadge => 'Jag';

  @override
  String onlinePlayingAs(String name) {
    return 'Du spelar som ”$name”';
  }

  @override
  String get onlineNameInvalidError =>
      'Online får ditt smeknamn (eller ditt namn) vara högst 20 tecken, utan osynliga tecken.';

  @override
  String get settingsDiceSoundLabel => 'Tärningsljud';

  @override
  String get settingsDiceSoundRealistic => 'Realistiskt';

  @override
  String get settingsDiceSoundSynthetic => 'Syntetiskt';

  @override
  String get homeChipsHint => 'Tryck länge på en mark för att se namnet.';

  @override
  String get emoteThoughtful => 'Fundersam';

  @override
  String get emoteMocking => 'Dör av skratt';

  @override
  String get emoteDevastated => 'Förkrossad';

  @override
  String get emoteJoyful => 'Kram';

  @override
  String get emotePhraseCoincidence => 'Vilket sammanträffande...';

  @override
  String get emotePhraseStickyFive => 'Femman som klistrar!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Full hand, tom hand!';

  @override
  String get emotePhraseNeverTakeA1000 => 'En 1000 tar man aldrig över!';

  @override
  String get emotePhraseNoWay => 'Helt enkelt omöjligt!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Hej!';

  @override
  String get emotePhraseYes => 'Ja!';

  @override
  String get emotePhraseTooGreedy => 'För girig!';

  @override
  String get emotePhraseTooLucky => 'Lite väl turlig...';

  @override
  String get emotePhraseDryTenThousand => 'Raka vägen till 10000';

  @override
  String get emotePhraseLucky => 'Din lyckost!';

  @override
  String get emotePhraseGoodLuck => 'Lycka till!';

  @override
  String get emotePhraseThanks => 'Tack';

  @override
  String get emotePhraseSorryMustGo => 'Förlåt, men jag måste gå';

  @override
  String get gameHistoryBar => 'Historik';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'En ny version finns tillgänglig ($version, bygge $build).';
  }

  @override
  String get updateNowButton => 'Uppdatera';

  @override
  String get updateLaterButton => 'Senare';
}
