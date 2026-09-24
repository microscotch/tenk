// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get splashPresents => 'presenterer';

  @override
  String get validateButton => 'Bekreft';

  @override
  String get settingsTooltip => 'Innstillinger';

  @override
  String get helpTooltip => 'Spilleregler';

  @override
  String get aboutTooltip => 'Om';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versjon $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Lukk';

  @override
  String playersCountTitle(int count) {
    return 'Spillere ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Start spillet';

  @override
  String get newGameSectionLabel => 'Ny run...';

  @override
  String get resumeGamesButton => 'Fortsett spill';

  @override
  String get managePlayersButton => 'Administrer spillere';

  @override
  String get finishedGamesButton => 'Sist fullførte spill';

  @override
  String get statisticsButton => 'Statistikk';

  @override
  String playersScreenTitle(int count) {
    return 'Spillere ($count)';
  }

  @override
  String get addPlayerTooltip => 'Legg til en spiller';

  @override
  String get noPlayersMessage => 'Ingen lagrede spillere ennå.';

  @override
  String get newPlayerTitle => 'Ny spiller';

  @override
  String get editPlayerTitle => 'Rediger spiller';

  @override
  String get playerNameLabel => 'Navn';

  @override
  String get playerNicknameLabel => 'Kallenavn (valgfritt)';

  @override
  String get playerNameRequiredError => 'Navn er påkrevd.';

  @override
  String get playerNameTakenError =>
      'Dette navnet brukes allerede av en annen spiller.';

  @override
  String get deletePlayerConfirmTitle => 'Slette denne spilleren?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Profilen til «$name» og statistikken blir slettet for godt. Spill som allerede er spilt, beholdes.';
  }

  @override
  String get statsSectionTime => 'Spilletid';

  @override
  String get statsSectionGames => 'Spill';

  @override
  String get statsSectionFigures => 'Kombinasjoner';

  @override
  String get statsSectionRolls => 'Runder og kast';

  @override
  String get statsTurns => 'Spilte runder';

  @override
  String get statsRolls => 'Kast';

  @override
  String get statsRollsPerTurn => 'Kast per runde';

  @override
  String get statsSectionMisc => 'Bragder';

  @override
  String get statsTotalTime => 'Totalt';

  @override
  String get statsAverageTime => 'Snitt per spill';

  @override
  String get statsShortestTime => 'Korteste';

  @override
  String get statsLongestTime => 'Lengste';

  @override
  String get statsGamesPlayed => 'Spilt';

  @override
  String get statsGamesWon => 'Vunnet';

  @override
  String get statsGamesLost => 'Tapt';

  @override
  String get statsLoneAces => 'Enkeltstående enere beholdt';

  @override
  String get statsLoneFives => 'Enkeltstående femmere beholdt';

  @override
  String get statsBrelans => 'Tre like';

  @override
  String get statsCarres => 'Fire like';

  @override
  String get statsQuintes => 'Fem like';

  @override
  String get statsSuites => 'Straights';

  @override
  String get statsSmallSuites => 'hvorav små';

  @override
  String get statsBigSuites => 'hvorav store';

  @override
  String get statsAceQuints => 'Fem enere';

  @override
  String get statsAceQuintsWon => 'hvorav vinnende';

  @override
  String get statsBestTurn => 'Beste runde';

  @override
  String get statsHotDiceRun => 'Varme terninger på rad';

  @override
  String get statsBusts => 'Bom';

  @override
  String get statsLongestBustStreak => 'lengste rekke';

  @override
  String get statsSelfBars => 'Strøket selv';

  @override
  String get statsBarsInflicted => 'Strøket for andre';

  @override
  String get scoreChartTitle => 'Poengutvikling';

  @override
  String get gameStatsTitle => 'Spillstatistikk';

  @override
  String get gameStatsGameSection => 'Spill';

  @override
  String get gameStatsFiguresSection => 'Kombinasjoner i spillet';

  @override
  String get gameStatsDuration => 'Spilletid';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns runder',
      one: '$turns runde',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts bom',
      one: '$busts bom',
    );
    return '$_temp0 · beste $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games spill',
      one: '$games spill',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won vunnet',
      one: '$won vunnet',
    );
    return '$_temp0 · $_temp1 · beste $best';
  }

  @override
  String get scoreChartEmpty =>
      'Ingen runde er ferdig ennå: det er ingenting å tegne.';

  @override
  String get replayUnavailable =>
      'Dette spillet kan ikke spilles av på nytt: loggen er ufullstendig.';

  @override
  String get replayPlay => 'Spill av';

  @override
  String get replayPause => 'Pause';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Runde $turn';
  }

  @override
  String get scoreChartXAxis => 'Spilte runder';

  @override
  String get statsBreakdownRow => 'hvorav';

  @override
  String get statsRecordsTitle => 'Rekorder';

  @override
  String get statsNoRecordYet => 'Ingen rekorder ennå.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Velg spillere';

  @override
  String get addHumanTooltip => 'Legg til en spiller';

  @override
  String get addBotTooltip => 'Legg til en bot';

  @override
  String get createPlayerButton => 'Ny spiller';

  @override
  String get noPlayersToPickMessage =>
      'Ingen lagrede spillere. Opprett en for å begynne.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Fjern fra spillet';

  @override
  String get notEnoughPlayersMessage => 'Det trengs minst to spillere.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spill spilt',
      one: '$count spill spilt',
      zero: 'Ingen spill spilt',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Avbrutte runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Fullførte runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Ingen pausede spill ennå.';

  @override
  String get noFinishedRunsMessage => 'Ingen fullførte runs ennå.';

  @override
  String get gameRunParticipantsSeparator => ' mot ';

  @override
  String get deleteGameConfirmTitle => 'Slette dette spillet?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Spillet «$alias» blir slettet for godt.';
  }

  @override
  String get cancelButton => 'Avbryt';

  @override
  String get deleteButton => 'Slett';

  @override
  String get resumeLastGameDialogTitle => 'Fortsette spillet?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Spillet «$alias» pågår. Vil du fortsette det?';
  }

  @override
  String get resumeGameButton => 'Fortsett';

  @override
  String get gameOverReplayButton => 'Se spillet igjen';

  @override
  String get scoreGridLabel => 'Poengtabell';

  @override
  String get finalRoundBanner => 'Siste runde: en spiller har nådd 10000!';

  @override
  String get currentRollZoneLabel => 'Bane';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Bane ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Nåværende hånd';

  @override
  String get logHotDiceMessage => 'Varme terninger!';

  @override
  String get logScoreCollisionMessage => 'Poengsum strøket:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return '$kept: $gain, $_temp0 => $total p';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, varme terninger => $total p';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score p notert => $total p';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score p overtatt';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Bom! => $score strek';
  }

  @override
  String get logBustBarredPrefix => 'Bom! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'tilbake til $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Å overta denne hånden ville allerede overskride 10000: kan ikke stoppe.';

  @override
  String get rollButton => 'Kast';

  @override
  String get showProbabilitiesSetting => 'Vis sannsynligheter';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Viser på «Kast»-knappen sjansen for å få minst ett poeng';

  @override
  String get stopButton => 'Stopp';

  @override
  String get bustedTitle => 'Bom!';

  @override
  String get bustExceedsTarget => 'Dette kastet ville overskride 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Varme terninger på 10000: du kan ikke stoppe, og å kaste alt på nytt ville gått over.';

  @override
  String get bustContinueButton => 'Fortsett';

  @override
  String get inheritedHandDialogTitle => 'Overta?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terninger',
      one: '$count terning',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Overta hånden';

  @override
  String get newHandButton => 'Ny hånd';

  @override
  String get failureBelowMinimum => 'For lav poengsum til å stoppe.';

  @override
  String get failureEndsIn50 =>
      'Du kan ikke stoppe på en poengsum som ender på 50.';

  @override
  String get failureMustContinueHotDice => 'Du må kaste på nytt.';

  @override
  String get failureNotRolledYet => 'Du må kaste terningene før du kan stoppe.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Å stoppe nå ville gjort det umulig å nå nøyaktig 10000.';

  @override
  String get settingsMainPlayerTitle => 'Hovedspiller';

  @override
  String get settingsYourNameLabel => 'Ditt navn (eier av enheten)';

  @override
  String get settingsDelaysTitle => 'Forsinkelser';

  @override
  String get settingsDelaysDescription =>
      'Forsinkelse før en automatisk handling utløses av seg selv. 0 for å deaktivere.';

  @override
  String get settingsAiDelayLabel => 'KI-meldinger (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatiske handlinger for den menneskelige spilleren (ms)';

  @override
  String get settingsDiceTitle => 'Terninger';

  @override
  String get settingsDiceUniform => 'Ensfarget';

  @override
  String get settingsDiceVaried => 'Blandet';

  @override
  String get settingsSoundsTitle => 'Lyd';

  @override
  String get settingsMusicLabel => 'Bakgrunnsmusikk';

  @override
  String get settingsSoundEffectsLabel => 'Lydeffekter';

  @override
  String get settingsHandednessLabel => 'Plassering av knapper';

  @override
  String get settingsHandednessRight => 'Høyrehendt';

  @override
  String get settingsHandednessLeft => 'Venstrehendt';

  @override
  String get settingsControlsTitle => 'Kontroller';

  @override
  String get settingsShakeToRollLabel => 'Rist for å kaste terningene';

  @override
  String get settingsPausedGamesTitle => 'Pausede spill';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Bekreft før du sletter et spill';

  @override
  String get settingsLanguageTitle => 'Språk';

  @override
  String get settingsLanguageSystemOption => 'Telefonens språk';

  @override
  String get reorderPlayersHint =>
      'Dra en spiller i håndtaket for å endre rekkefølgen rundt bordet.';

  @override
  String get reorderPlayerHandleLabel => 'Flytt denne spilleren';

  @override
  String get diceOffTitle => 'Hvem begynner?';

  @override
  String get diceOffInstructions =>
      'Alle kaster terningen samtidig: den laveste begynner. Ved likt kaster de som står likt på nytt.';

  @override
  String diceOffTieBreak(String names) {
    return 'Uavgjort: $names kaster på nytt.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName begynner spillet!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Spillrekkefølge';

  @override
  String get diceOffReversedNote =>
      'Duell mellom naboer vunnet av den andre: spillet går motsatt vei.';

  @override
  String get gameOverTitle => 'Spillet er over';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vinner!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Gi enheten videre til';

  @override
  String get readyButton => 'Klar';

  @override
  String get notEnteredLabel => '(ikke inne ennå)';

  @override
  String get opportunityTooltip =>
      '200 poeng unna å stryke spilleren rett over!';

  @override
  String get dangerTooltip =>
      'Fare: spilleren rett under er bare 200 poeng unna, risiko for å stryke deg';

  @override
  String get tiretTooltip => 'Strek: en ny bom vil stryke poengsummen';

  @override
  String get previousScoreHadTiretTooltip => 'Forrige poengsum hadde en strek';

  @override
  String get rankFirstTooltip => 'I ledelsen';

  @override
  String get rankSecondTooltip => 'Nr. 2 på poeng';

  @override
  String get rankThirdTooltip => 'Nr. 3 på poeng';

  @override
  String get rulesScreenTitle => 'Spilleregler';

  @override
  String get rulesGoalTitle => 'Målet med spillet';

  @override
  String get rulesGoalBody =>
      'Den første spilleren som når nøyaktig 10 000 poeng, vinner spillet. Du må treffe tallet nøyaktig: å gå over teller ikke.';

  @override
  String get rulesTurnTitle => 'Slik spilles en runde';

  @override
  String get rulesTurnBody =>
      'På din tur kaster du 5 terninger. Noen verdier gir poeng (se under), andre gir ingenting. Du legger til side minst én terning som gir poeng, og velger så: kaste de gjenværende terningene på nytt for å prøve å samle flere poeng, eller stoppe og notere det du har samlet denne runden. Hvis et kast ikke gir ett eneste poeng, er det bom (se under), og du mister alt du hadde samlet denne runden.';

  @override
  String get rulesScoringTitle => 'Hva som gir poeng';

  @override
  String get rulesScoringBody =>
      '• En enkeltstående ener: 100 poeng. En enkeltstående femmer: 50 poeng. Andre enkeltstående verdier (2, 3, 4, 6) gir ingenting.\n• Tre like terninger: 1000 poeng for tre enere, ellers terningens verdi × 100 (tre firere er verdt 400, tre seksere 600).\n• En fjerde terning med samme verdi gir 1000 poeng til.\n• Fem like terninger er verdt terningens verdi × 1000, bortsett fra fem enere, som gir 10 000 poeng direkte: umiddelbar seier.\n• En straight med 5 påfølgende terninger (1-2-3-4-5 eller 2-3-4-5-6) er verdt 500 poeng.';

  @override
  String get rulesHotDiceTitle => 'Varme terninger: en tvungen ny sjanse';

  @override
  String get rulesHotDiceBody =>
      'Hvis alle terningene du nettopp kastet gir poeng, må du kaste alle 5 terningene på nytt: du kan ikke stoppe akkurat da. Dette kalles «varme terninger».';

  @override
  String get rulesBustTitle => 'Bom';

  @override
  String get rulesBustBody =>
      'Hvis et kast ikke gir noen poeng i det hele tatt, slutter runden din umiddelbart, og du mister alle poengene du har samlet denne runden (det du noterte i tidligere runder, beholder du). En bom markerer også den nåværende poenglinjen din med en strek; hadde den allerede en, blir den strøket, og poengsummen din faller tilbake til forrige verdi.';

  @override
  String get rulesEntryTitle => 'Komme inn i spillet';

  @override
  String get rulesEntryBody =>
      'For å begynne å få poeng må din aller første vellykkede runde gi minst 500 poeng. Når du først er inne i spillet, må hver påfølgende runde gi minst 200 poeng før du kan stoppe.';

  @override
  String get rulesNoFiftyTitle => 'Aldri en poengsum som slutter på 50';

  @override
  String get rulesNoFiftyBody =>
      'Du kan aldri velge å stoppe frivillig på en rundesum som slutter på 50 (som 250 eller 450): du må kaste på nytt til du får en gyldig sum.';

  @override
  String get rulesExtensionTitle => 'Utvidelsesregelen';

  @override
  String get rulesExtensionBody =>
      'Når du har notert tre eller fire like av en bestemt verdi (for eksempel tre firere), er hver enkeltstående terning med samme verdi som kommer senere i samme runde verdt 100 poeng i stedet for sin vanlige verdi — også en enkeltstående femmer, som da er verdt 100 i stedet for 50. Fordelen forsvinner så snart du får varme terninger.';

  @override
  String get rulesInheritTitle => 'Arve terningene til forrige spiller';

  @override
  String get rulesInheritBody =>
      'Når en spiller stopper frivillig og fortsatt har ukastede terninger, kan neste spiller velge å overta disse gjenværende terningene sammen med poengsummen som allerede er samlet, som utgangspunkt, eller begynne på nytt med 5 nye terninger. Etter en bom begynner neste spiller derimot alltid med 5 nye terninger, uten å arve noe.';

  @override
  String get rulesBarredTitle => 'Strek og strøket';

  @override
  String get rulesBarredBody =>
      'En bom setter en varselstrek på den nåværende poenglinjen din hvis den ikke allerede har en. Har den det, blir linjen strøket, og poengsummen din faller tilbake til forrige verdi. Hvis poengsummen din blir nøyaktig lik en annen spillers, blir den spilleren strøket på samme måte, enten vedkommende allerede hadde en strek eller ikke.';

  @override
  String get rulesVictoryTitle => 'Slik vinner du';

  @override
  String get rulesVictoryBody =>
      'Den første spilleren som når nøyaktig 10 000 poeng, utløser en siste runde: hver av de andre spillerne får en siste sjanse på sin tur til å ta igjen eller slå vedkommende. Hvis en annen spiller også når nøyaktig 10 000 i løpet av denne siste runden, tar han eller hun over kronen, og en ny siste runde starter rundt dem.';
}
