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
  String get failureMustContinueFinalRound =>
      'Du kannst nicht aufhören: Die letzte Runde erfordert genau 10000 Punkte.';

  @override
  String get failureNotRolledYet =>
      'Du musst würfeln, bevor du aufhören kannst.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Jetzt aufzuhören würde es unmöglich machen, genau 10000 zu erreichen.';

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
  String get tutorialTitle => 'Tutorial';

  @override
  String get tutorialSkip => 'Überspringen';

  @override
  String get tutorialPlayerName => 'Du';

  @override
  String get tutorialNext => 'Weiter';

  @override
  String get tutorialFinish => 'Spielen';

  @override
  String get tutorialReplayButton => 'Tutorial noch einmal ansehen';

  @override
  String get tutorialStep0 =>
      'Willkommen bei Le 10000! Ziel: genau 10.000 Punkte erreichen. Wir spielen einen Zug gemeinsam auf dem echten Spielbildschirm: nichts wird gespeichert.';

  @override
  String get tutorialStep1 =>
      'Tippe auf den Würfeln-Knopf, um die 5 Würfel zu werfen.';

  @override
  String get tutorialStep2 =>
      'Nur die 1 (100) und die 5 (50) zählen hier: sie bleiben liegen, die Hand ist 150 wert. Zum Einstieg braucht man 500 Punkte: wirf die anderen 3 Würfel neu.';

  @override
  String get tutorialStep3 =>
      'Drei 3en: 300 Punkte, die Hand steigt auf 450. Alle Würfel haben gezählt: heiße Würfel! Du wirfst alle 5 neu und darfst nicht aufhören.';

  @override
  String get tutorialStep4 =>
      'Zwei 5en, aber sie sind freiwillig: dieser Wähler bestimmt, wie viele du behältst. Mit beiden würden 550 auf 50 enden: Aufhören wäre unmöglich. Wähle 1.';

  @override
  String get tutorialStep5 =>
      '500 Punkte: genug zum Einstieg, und keine 50 am Ende. Tippe auf die Hand, um aufzuhören und sie zu verbuchen.';

  @override
  String get tutorialStep6 =>
      '500 Punkte verbucht! Der Bot ist dran; ein Wurf ohne Punkte ist ein Fehlwurf (Zug verloren, ein Strich auf der Zeile). Wer als Erster genau 10.000 erreicht, gewinnt. Die vollständigen Regeln stehen im Menü.';

  @override
  String get rulesGoalTitle => 'Ziel des Spiels';

  @override
  String get rulesGoalBody =>
      'Genau 10.000 Punkte erreichen. Überschreiten zählt nicht.';

  @override
  String get rulesTurnTitle => 'Ablauf eines Zuges';

  @override
  String get rulesTurnBody =>
      'Du würfelst 5 Würfel, legst mindestens einen punktebringenden Würfel beiseite und würfelst dann die übrigen neu oder hörst auf und verbuchst. Bringt ein Wurf nichts, ist es ein Fehlwurf: Du verlierst alles, was du in diesem Zug gesammelt hast.';

  @override
  String get rulesScoringTitle => 'Was Punkte bringt';

  @override
  String get rulesScoringBody =>
      '• Eine einzelne 1: 100 Punkte. Eine einzelne 5: 50 Punkte. Andere einzelne Werte (2, 3, 4, 6) bringen nichts.\n• Ein Drilling: Augenzahl × 100 (drei 6en sind 600 wert), außer drei 1en: 1000.\n• Ein Vierling: 1000 Punkte mehr als der passende Drilling (vier 6en sind 1600 wert, vier 1en 2000).\n• Fünf gleiche Würfel sind Augenzahl × 1000 wert. Fünf 1en bringen direkt 10.000 Punkte: der sofortige Sieg.\n• Eine Straße aus 5 aufeinanderfolgenden Würfeln (1-2-3-4-5 oder 2-3-4-5-6) ist 500 Punkte wert.';

  @override
  String get rulesBustTitle => 'Fehlwurf und Streichung';

  @override
  String get rulesBustBody =>
      'Ein Fehlwurf setzt einen Strich auf deine aktuelle Punktezeile. Hatte sie schon einen, wird sie gestrichen und du fällst auf deinen vorigen Stand zurück. Erreichst du dieselbe Summe wie ein anderer Spieler, wird dieser gestrichen.';

  @override
  String get rulesEntryTitle => 'Aufhören';

  @override
  String get rulesEntryBody =>
      '• Du brauchst mindestens 500 Punkte, um ins Spiel zu kommen, danach mindestens 200 pro Zug.\n• Du darfst nie bei einer Zugsumme aufhören, die auf 50 endet (250, 450…).\n• Bringen alle deine Würfel Punkte („heiße Würfel“), musst du alle 5 neu würfeln.';

  @override
  String get rulesExtensionTitle => 'Die Erweiterungsregel';

  @override
  String get rulesExtensionBody =>
      'Hast du einen Drilling oder Vierling verbucht, ist jeder einzelne Würfel desselben Werts später im Zug 100 wert, auch eine 5. Bei heißen Würfeln entfällt das.';

  @override
  String get rulesInheritTitle => 'Die Würfel des vorigen Spielers erben';

  @override
  String get rulesInheritBody =>
      'Hörst du mit ungeworfenen Würfeln auf, darf der nächste Spieler diese Würfel samt deinem Punktestand als Basis übernehmen oder mit 5 neuen Würfeln beginnen. Nach einem Fehlwurf beginnt er immer mit 5 neuen Würfeln.';

  @override
  String get rulesVictoryTitle => 'Genau 10.000 und Schlussrunde';

  @override
  String get rulesVictoryBody =>
      'Sobald ein Wurf genau 10.000 ermöglicht, erfolgt die Aufnahme automatisch und der Zug endet. Die anderen Spieler haben dann einen letzten Zug, um gleichzuziehen: Darin darf niemand unter 10.000 aufhören, man muss gleichziehen oder einen Fehlwurf machen. Erreicht ein anderer Spieler ebenfalls genau 10.000, streicht er den ersten und eine neue Schlussrunde beginnt um ihn herum.\nSonderfall: Eine volle Hand, die genau auf 10.000 fällt, ist ein Fehlwurf, da sie zum Weiterwürfeln zwingt. Nur das Ass-Quintett gewinnt.';

  @override
  String get onlinePlayButton => 'Online spielen';

  @override
  String get onlineResumeButton => 'Online-Spiel fortsetzen';

  @override
  String get onlineTitle => 'Online-Spiel';

  @override
  String get onlineCreateButton => 'Raum erstellen';

  @override
  String get onlineJoinButton => 'Beitreten';

  @override
  String get onlineCodeLabel => 'Raumcode';

  @override
  String get onlineOrDivider => 'oder';

  @override
  String get onlineShareHint =>
      'Gib diesen Code an die anderen Spieler weiter, damit sie beitreten können.';

  @override
  String get onlineShareButton => 'Code teilen';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Tritt meiner Online-Partie von Le 10000 bei! Raumcode: $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Spieler ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Gastgeber';

  @override
  String get onlineDisconnectedBadge => 'Getrennt';

  @override
  String get onlineNeedTwoPlayers =>
      'Es braucht mindestens 2 Spieler, alle verbunden.';

  @override
  String get onlineWaitingForHost => 'Warten, bis der Gastgeber startet …';

  @override
  String get onlineLeaveButton => 'Verlassen';

  @override
  String get onlineLeaveConfirmTitle => 'Online-Spiel verlassen?';

  @override
  String get onlineLeaveConfirmBody =>
      'In einem begonnenen Spiel bleibt dein Platz leer und das Spiel wartet auf deine Rückkehr.';

  @override
  String get onlineConnecting => 'Verbindung zum Server …';

  @override
  String get onlineReconnecting => 'Verbindung verloren, verbinde neu …';

  @override
  String get onlineSuspended =>
      'Spiel unterbrochen: Ein Spieler ist zu lange abwesend.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName ist am Zug …';
  }

  @override
  String get onlineDiceOffContinue => 'Spielen';

  @override
  String get onlineErrorUnreachable => 'Server nicht erreichbar.';

  @override
  String get onlineErrorRoomNotFound => 'Kein Raum mit diesem Code.';

  @override
  String get onlineErrorRoomFull => 'Dieser Raum ist voll.';

  @override
  String get onlineErrorGameStarted => 'Dieses Spiel hat bereits begonnen.';

  @override
  String get onlineErrorRateLimited =>
      'Zu viele Versuche: Versuche es gleich noch einmal.';

  @override
  String get onlineErrorBadToken =>
      'Dein Platz in diesem Raum existiert nicht mehr.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Aktualisiere die App, um online zu spielen.';

  @override
  String get onlineErrorGeneric => 'Es ist ein Fehler aufgetreten.';

  @override
  String get myProfileTitle => 'Mein Profil';

  @override
  String get myProfileWelcomeTitle => 'Willkommen!';

  @override
  String get myProfileWelcomeMessage =>
      'Erstelle dein Profil: deinen Namen, auf Wunsch einen Spitznamen, und die Hand, mit der du spielst. Online sehen die anderen Spieler deinen Spitznamen oder, falls du keinen hast, deinen Namen.';

  @override
  String get myProfileExistingPrompt =>
      'Schon in der Spielerliste? Tippe auf deinen Namen.';

  @override
  String get myProfileCreateButton => 'Mein Profil erstellen';

  @override
  String get myProfileEditButton => 'Mein Profil bearbeiten';

  @override
  String get myProfileBadge => 'Ich';

  @override
  String onlinePlayingAs(String name) {
    return 'Du spielst als „$name“';
  }

  @override
  String get onlineNameInvalidError =>
      'Online darf dein Spitzname (oder dein Name) höchstens 20 Zeichen lang sein, ohne unsichtbare Zeichen.';

  @override
  String get settingsDiceSoundLabel => 'Würfelgeräusch';

  @override
  String get settingsDiceSoundRealistic => 'Realistisch';

  @override
  String get settingsDiceSoundSynthetic => 'Synthetisch';

  @override
  String get homeChipsHint =>
      'Lange auf einen Jeton drücken, um seinen Namen zu sehen.';

  @override
  String get emoteThoughtful => 'Nachdenklich';

  @override
  String get emoteMocking => 'Totgelacht';

  @override
  String get emoteDevastated => 'Am Boden zerstört';

  @override
  String get emoteJoyful => 'Umarmung';

  @override
  String get emotePhraseCoincidence => 'Was für ein Zufall...';

  @override
  String get emotePhraseStickyFive => 'Die Fünf klebt!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Volle Hand, leere Hand!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Eine 1000 übernimmt man nie!';

  @override
  String get emotePhraseNoWay => 'Einfach nicht möglich!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Hallo!';

  @override
  String get emotePhraseYes => 'Ja!';

  @override
  String get emotePhraseTooGreedy => 'Zu gierig!';

  @override
  String get emotePhraseTooLucky => 'Ein bisschen zu viel Glück...';

  @override
  String get emotePhraseDryTenThousand => 'Die 10000 auf einen Schlag';

  @override
  String get emotePhraseLucky => 'Du Glückspilz!';

  @override
  String get emotePhraseGoodLuck => 'Viel Glück!';

  @override
  String get emotePhraseThanks => 'Danke';

  @override
  String get emotePhraseSorryMustGo => 'Sorry, aber ich muss los';

  @override
  String get gameHistoryBar => 'Verlauf';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'Eine neue Version ist verfügbar ($version, Build $build).';
  }

  @override
  String get updateNowButton => 'Aktualisieren';

  @override
  String get updateLaterButton => 'Später';
}
