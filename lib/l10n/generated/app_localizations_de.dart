// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get splashPresents => 'präsentiert';

  @override
  String get validateButton => 'Bestätigen';

  @override
  String get settingsTooltip => 'Einstellungen';

  @override
  String get helpTooltip => 'Spielregeln';

  @override
  String get aboutTooltip => 'Über';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Version $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Schließen';

  @override
  String playersCountTitle(int count) {
    return 'Spieler ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Spiel starten';

  @override
  String get newGameSectionLabel => 'Neuer Run...';

  @override
  String get resumeGamesButton => 'Spiele fortsetzen';

  @override
  String get managePlayersButton => 'Spieler verwalten';

  @override
  String get finishedGamesButton => 'Zuletzt beendete Spiele';

  @override
  String get statisticsButton => 'Statistiken';

  @override
  String playersScreenTitle(int count) {
    return 'Spieler ($count)';
  }

  @override
  String get addPlayerTooltip => 'Spieler hinzufügen';

  @override
  String get noPlayersMessage => 'Noch keine Spieler gespeichert.';

  @override
  String get newPlayerTitle => 'Neuer Spieler';

  @override
  String get editPlayerTitle => 'Spieler bearbeiten';

  @override
  String get playerNameLabel => 'Name';

  @override
  String get playerNicknameLabel => 'Spitzname (optional)';

  @override
  String get playerNameRequiredError => 'Der Name ist erforderlich.';

  @override
  String get playerNameTakenError =>
      'Dieser Name wird bereits von einem anderen Spieler verwendet.';

  @override
  String get deletePlayerConfirmTitle => 'Diesen Spieler löschen?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'Das Profil von „$name“ und seine Statistiken werden endgültig gelöscht. Bereits gespielte Spiele bleiben erhalten.';
  }

  @override
  String get statsSectionTime => 'Spielzeit';

  @override
  String get statsSectionGames => 'Spiele';

  @override
  String get statsSectionFigures => 'Kombinationen';

  @override
  String get statsSectionRolls => 'Züge und Würfe';

  @override
  String get statsTurns => 'Gespielte Züge';

  @override
  String get statsRolls => 'Würfe';

  @override
  String get statsRollsPerTurn => 'Würfe pro Zug';

  @override
  String get statsSectionMisc => 'Heldentaten';

  @override
  String get statsTotalTime => 'Gesamt';

  @override
  String get statsAverageTime => 'Durchschnitt pro Spiel';

  @override
  String get statsShortestTime => 'Kürzestes';

  @override
  String get statsLongestTime => 'Längstes';

  @override
  String get statsGamesPlayed => 'Gespielt';

  @override
  String get statsGamesWon => 'Gewonnen';

  @override
  String get statsGamesLost => 'Verloren';

  @override
  String get statsLoneAces => 'Einzelne 1en behalten';

  @override
  String get statsLoneFives => 'Einzelne 5en behalten';

  @override
  String get statsBrelans => 'Drillinge';

  @override
  String get statsCarres => 'Vierlinge';

  @override
  String get statsQuintes => 'Fünflinge';

  @override
  String get statsSuites => 'Straßen';

  @override
  String get statsSmallSuites => 'davon kleine';

  @override
  String get statsBigSuites => 'davon große';

  @override
  String get statsAceQuints => 'Fünf 1en';

  @override
  String get statsAceQuintsWon => 'davon siegreich';

  @override
  String get statsBestTurn => 'Bester Zug';

  @override
  String get statsHotDiceRun => 'Heiße Würfel in Folge';

  @override
  String get statsBusts => 'Fehlwürfe';

  @override
  String get statsLongestBustStreak => 'längste Serie';

  @override
  String get statsSelfBars => 'Selbst gestrichen';

  @override
  String get statsBarsInflicted => 'Andere gestrichen';

  @override
  String get scoreChartTitle => 'Punkteverlauf';

  @override
  String get gameStatsTitle => 'Spielstatistiken';

  @override
  String get gameStatsGameSection => 'Spiel';

  @override
  String get gameStatsFiguresSection => 'Kombinationen im Spiel';

  @override
  String get gameStatsDuration => 'Spielzeit';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns Züge',
      one: '$turns Zug',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts Fehlwürfe',
      one: '$busts Fehlwurf',
    );
    return '$_temp0 · bester $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games Spiele',
      one: '$games Spiel',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won gewonnen',
      one: '$won gewonnen',
    );
    return '$_temp0 · $_temp1 · bester $best';
  }

  @override
  String get scoreChartEmpty =>
      'Noch kein Zug beendet: Es gibt noch nichts darzustellen.';

  @override
  String get replayUnavailable =>
      'Dieses Spiel kann nicht wiedergegeben werden: sein Protokoll ist unvollständig.';

  @override
  String get replayPlay => 'Abspielen';

  @override
  String get replayPause => 'Pause';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Zug $turn';
  }

  @override
  String get scoreChartXAxis => 'Gespielte Züge';

  @override
  String get statsBreakdownRow => 'davon';

  @override
  String get statsRecordsTitle => 'Rekorde';

  @override
  String get statsNoRecordYet => 'Noch keine Rekorde.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Spieler auswählen';

  @override
  String get addHumanTooltip => 'Spieler hinzufügen';

  @override
  String get addBotTooltip => 'Bot hinzufügen';

  @override
  String get createPlayerButton => 'Neuer Spieler';

  @override
  String get noPlayersToPickMessage =>
      'Keine Spieler gespeichert. Lege einen an, um zu beginnen.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Aus dem Spiel entfernen';

  @override
  String get notEnoughPlayersMessage =>
      'Es werden mindestens zwei Spieler benötigt.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Spiele gespielt',
      one: '$count Spiel gespielt',
      zero: 'Noch kein Spiel gespielt',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Unterbrochene Runs ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Beendete Runs ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Noch keine pausierten Spiele.';

  @override
  String get noFinishedRunsMessage => 'Noch keine beendeten Runs.';

  @override
  String get gameRunParticipantsSeparator => ' vs. ';

  @override
  String get deleteGameConfirmTitle => 'Dieses Spiel löschen?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'Das Spiel „$alias“ wird endgültig gelöscht.';
  }

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get resumeLastGameDialogTitle => 'Spiel fortsetzen?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Ein Spiel „$alias“ läuft noch. Möchtest du es fortsetzen?';
  }

  @override
  String get resumeGameButton => 'Fortsetzen';

  @override
  String get gameOverReplayButton => 'Spiel noch einmal ansehen';

  @override
  String get scoreGridLabel => 'Punktetabelle';

  @override
  String get finalRoundBanner =>
      'Letzte Runde: Ein Spieler hat 10000 erreicht!';

  @override
  String get currentRollZoneLabel => 'Spielfeld';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Spielfeld ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Aktuelle Hand';

  @override
  String get logHotDiceMessage => 'Heiße Würfel!';

  @override
  String get logScoreCollisionMessage => 'Punktzahl gestrichen:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfel',
      one: '$count Würfel',
    );
    return '$kept: $gain, $_temp0 => $total Pkt.';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, heiße Würfel => $total Pkt.';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score Pkt. eingelöst => $total Pkt.';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score Pkt. übernommen';
  }

  @override
  String logBustTiretMessage(int score) {
    return 'Fehlwurf! => $score Strich';
  }

  @override
  String get logBustBarredPrefix => 'Fehlwurf! =>';

  @override
  String logBustBarredReturnMessage(int score) {
    return 'zurück auf $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Diese Hand zu übernehmen würde bereits 10000 überschreiten: Einlösen nicht möglich.';

  @override
  String get rollButton => 'Würfeln';

  @override
  String get showProbabilitiesSetting => 'Wahrscheinlichkeiten anzeigen';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Zeigt auf der Schaltfläche „Würfeln“ die Chance, mindestens einen Punkt zu erzielen';

  @override
  String get stopButton => 'Aufhören';

  @override
  String get bustedTitle => 'Verloren!';

  @override
  String get bustExceedsTarget => 'Dieser Wurf würde 10000 überschreiten.';

  @override
  String get bustFullHandAtTarget =>
      'Heiße Würfel bei 10000: Aufhören ist nicht erlaubt, und alles neu zu würfeln würde überschreiten.';

  @override
  String get bustContinueButton => 'Weiter';

  @override
  String get inheritedHandDialogTitle => 'Übernehmen?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Würfel',
      one: '$count Würfel',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Hand übernehmen';

  @override
  String get newHandButton => 'Neue Hand';

  @override
  String get failureBelowMinimum => 'Punktzahl zu niedrig, um aufzuhören.';

  @override
  String get failureEndsIn50 =>
      'Du darfst nicht bei einer Punktzahl aufhören, die auf 50 endet.';

  @override
  String get failureMustContinueHotDice => 'Du musst erneut würfeln.';

  @override
  String get failureNotRolledYet =>
      'Du musst würfeln, bevor du aufhören kannst.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Jetzt aufzuhören würde es unmöglich machen, genau 10000 zu erreichen.';

  @override
  String get settingsMainPlayerTitle => 'Hauptspieler';

  @override
  String get settingsYourNameLabel => 'Dein Name (Gerätebesitzer)';

  @override
  String get settingsDelaysTitle => 'Verzögerungen';

  @override
  String get settingsDelaysDescription =>
      'Verzögerung, bevor eine automatische Aktion von selbst ausgelöst wird. 0 zum Deaktivieren.';

  @override
  String get settingsAiDelayLabel => 'KI-Nachrichten (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Automatische Aktionen des menschlichen Spielers (ms)';

  @override
  String get settingsDiceTitle => 'Würfel';

  @override
  String get settingsDiceUniform => 'Einheitlich';

  @override
  String get settingsDiceVaried => 'Bunt gemischt';

  @override
  String get settingsSoundsTitle => 'Sound';

  @override
  String get settingsMusicLabel => 'Hintergrundmusik';

  @override
  String get settingsSoundEffectsLabel => 'Soundeffekte';

  @override
  String get settingsHandednessLabel => 'Anordnung der Schaltflächen';

  @override
  String get settingsHandednessRight => 'Rechtshänder';

  @override
  String get settingsHandednessLeft => 'Linkshänder';

  @override
  String get settingsControlsTitle => 'Steuerung';

  @override
  String get settingsShakeToRollLabel => 'Schütteln zum Würfeln';

  @override
  String get settingsPausedGamesTitle => 'Pausierte Spiele';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Vor dem Löschen eines Spiels bestätigen';

  @override
  String get settingsLanguageTitle => 'Sprache';

  @override
  String get settingsLanguageSystemOption => 'Telefonsprache';

  @override
  String get reorderPlayersHint =>
      'Ziehe einen Spieler an seinem Griff, um die Reihenfolge am Tisch zu ändern.';

  @override
  String get reorderPlayerHandleLabel => 'Diesen Spieler verschieben';

  @override
  String get diceOffTitle => 'Wer beginnt?';

  @override
  String get diceOffInstructions =>
      'Alle würfeln gleichzeitig: Der Niedrigste beginnt. Bei Gleichstand würfeln die Gleichplatzierten erneut.';

  @override
  String diceOffTieBreak(String names) {
    return 'Unentschieden: $names würfeln erneut.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName beginnt das Spiel!';
  }

  @override
  String get diceOffPlayOrderLabel => 'Spielreihenfolge';

  @override
  String get diceOffReversedNote =>
      'Duell zwischen Nachbarn, vom Zweiten gewonnen: Es wird andersherum gespielt.';

  @override
  String get gameOverTitle => 'Spielende';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName gewinnt!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Gib das Gerät weiter an';

  @override
  String get readyButton => 'Bereit';

  @override
  String get notEnteredLabel => '(noch nicht eingestiegen)';

  @override
  String get opportunityTooltip =>
      'Nur 200 Punkte davon entfernt, den Spieler direkt darüber zu streichen!';

  @override
  String get dangerTooltip =>
      'Gefahr: Der Spieler direkt darunter ist nur 200 Punkte entfernt und könnte dich streichen';

  @override
  String get tiretTooltip =>
      'Strich: Ein zweiter Fehlwurf streicht die Punktzahl';

  @override
  String get previousScoreHadTiretTooltip =>
      'Die vorige Punktzahl trug einen Strich';

  @override
  String get rankFirstTooltip => 'In Führung';

  @override
  String get rankSecondTooltip => '2. nach Punkten';

  @override
  String get rankThirdTooltip => '3. nach Punkten';

  @override
  String get rulesScreenTitle => 'Spielregeln';

  @override
  String get rulesGoalTitle => 'Ziel des Spiels';

  @override
  String get rulesGoalBody =>
      'Wer als Erster genau 10.000 Punkte erreicht, gewinnt das Spiel. Man muss die Zahl genau treffen: Überschreiten zählt nicht.';

  @override
  String get rulesTurnTitle => 'Ablauf eines Zuges';

  @override
  String get rulesTurnBody =>
      'In deinem Zug würfelst du mit 5 Würfeln. Manche Augenzahlen bringen Punkte (siehe unten), andere nichts. Du legst mindestens einen punktenden Würfel beiseite und entscheidest dann: die übrigen Würfel erneut werfen, um mehr Punkte zu sammeln, oder aufhören und einlösen, was du in diesem Zug gesammelt hast. Bringt ein Wurf keinen einzigen Punkt, ist es ein Fehlwurf (siehe unten) und du verlierst alles, was du in diesem Zug gesammelt hattest.';

  @override
  String get rulesScoringTitle => 'Was Punkte bringt';

  @override
  String get rulesScoringBody =>
      '• Eine einzelne 1: 100 Punkte. Eine einzelne 5: 50 Punkte. Andere einzelne Werte (2, 3, 4, 6) bringen nichts.\n• Drei gleiche Würfel: 1000 Punkte für drei 1en, sonst Augenzahl × 100 (drei 4en sind 400 wert, drei 6en 600).\n• Ein vierter Würfel mit derselben Zahl bringt weitere 1000 Punkte.\n• Fünf gleiche Würfel sind Augenzahl × 1000 wert, außer fünf 1en, die direkt 10.000 Punkte bringen: der sofortige Sieg.\n• Eine Straße aus 5 aufeinanderfolgenden Würfeln (1-2-3-4-5 oder 2-3-4-5-6) ist 500 Punkte wert.';

  @override
  String get rulesHotDiceTitle => 'Heiße Würfel: eine erzwungene zweite Chance';

  @override
  String get rulesHotDiceBody =>
      'Bringen alle Würfel, die du gerade geworfen hast, Punkte, musst du alle 5 Würfel erneut werfen: In genau diesem Moment darfst du nicht aufhören. Das nennt man „heiße Würfel“.';

  @override
  String get rulesBustTitle => 'Der Fehlwurf';

  @override
  String get rulesBustBody =>
      'Bringt ein Wurf überhaupt keine Punkte, endet dein Zug sofort und du verlierst alle in diesem Zug gesammelten Punkte (was du in früheren Zügen eingelöst hast, bleibt dir). Ein Fehlwurf versieht außerdem deine aktuelle Punktezeile mit einem Strich; trug sie schon einen, wird sie gestrichen und deine Punktzahl fällt auf ihren vorigen Wert zurück.';

  @override
  String get rulesEntryTitle => 'Ins Spiel kommen';

  @override
  String get rulesEntryBody =>
      'Um Punkte zu schreiben, muss dein allererster erfolgreicher Zug mindestens 500 Punkte bringen. Bist du einmal im Spiel, muss jeder weitere Zug mindestens 200 Punkte bringen, damit du aufhören darfst.';

  @override
  String get rulesNoFiftyTitle => 'Nie eine Punktzahl, die auf 50 endet';

  @override
  String get rulesNoFiftyBody =>
      'Du darfst nie freiwillig bei einer Zugsumme aufhören, die auf 50 endet (etwa 250 oder 450): Du musst weiterwürfeln, bis die Summe gültig ist.';

  @override
  String get rulesExtensionTitle => 'Die Erweiterungsregel';

  @override
  String get rulesExtensionBody =>
      'Hast du einmal einen Drilling oder Vierling eines Wertes eingelöst (zum Beispiel drei 4en), bringt jeder einzelne Würfel dieses Wertes, der später im selben Zug fällt, 100 Punkte statt seines üblichen Werts — auch eine einzelne 5, die dann 100 statt 50 wert ist. Dieser Vorteil verfällt, sobald du heiße Würfel hast.';

  @override
  String get rulesInheritTitle => 'Die Würfel des vorigen Spielers erben';

  @override
  String get rulesInheritBody =>
      'Hört ein Spieler freiwillig auf, obwohl er noch ungeworfene Würfel hat, kann der nächste Spieler diese restlichen Würfel samt der bereits gesammelten Punkte als Ausgangsbasis übernehmen oder mit 5 neuen Würfeln bei null anfangen. Nach einem Fehlwurf dagegen beginnt der nächste Spieler immer mit 5 neuen Würfeln und erbt nichts.';

  @override
  String get rulesBarredTitle => 'Strich und gestrichen';

  @override
  String get rulesBarredBody =>
      'Ein Fehlwurf setzt einen Warnstrich auf deine aktuelle Punktezeile, falls sie noch keinen hat. Hat sie schon einen, wird die Zeile gestrichen und deine Punktzahl fällt auf ihren vorigen Wert zurück. Erreicht deine Punktzahl genau dieselbe Summe wie die eines anderen Spielers, wird dieser auf dieselbe Weise gestrichen, ob er schon einen Strich hatte oder nicht.';

  @override
  String get rulesVictoryTitle => 'Wie man gewinnt';

  @override
  String get rulesVictoryBody =>
      'Wer als Erster genau 10.000 Punkte erreicht, löst eine Schlussrunde aus: Jeder andere Spieler hat in seinem Zug eine letzte Chance, gleichzuziehen oder ihn zu übertreffen. Erreicht während dieser Schlussrunde ein anderer Spieler ebenfalls genau 10.000, übernimmt er die Krone und eine neue Schlussrunde beginnt um ihn herum.';
}
