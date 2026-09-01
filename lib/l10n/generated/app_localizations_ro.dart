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
  String get ownerNameDialogTitle => 'Cum te numești?';

  @override
  String get ownerNameFieldLabel => 'Numele jucătorului principal';

  @override
  String get laterButton => 'Mai târziu';

  @override
  String get validateButton => 'Confirmă';

  @override
  String get settingsTooltip => 'Setări';

  @override
  String playersCountTitle(int count) {
    return 'Jucători ($count)';
  }

  @override
  String defaultPlayerName(int number) {
    return 'Jucătorul $number';
  }

  @override
  String get unnamedPlayerFallback => 'Jucător';

  @override
  String playerNameFieldLabel(int number) {
    return 'Numele jucătorului $number';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get aiChipLabel => 'IA';

  @override
  String get addPlayerButton => 'Adaugă';

  @override
  String get removePlayerButton => 'Elimină';

  @override
  String get botDifficultyTitle => 'Dificultatea boților';

  @override
  String get aiDifficultyCautious => 'Prudent';

  @override
  String get aiDifficultyBalanced => 'Echilibrat';

  @override
  String get aiDifficultyAggressive => 'Agresiv';

  @override
  String get startGameButton => 'Începe jocul';

  @override
  String get newGameSectionLabel => 'Run nou...';

  @override
  String get pausedGamesSectionLabel => 'Run-uri întrerupte';

  @override
  String get finishedRunsSectionLabel => 'Run-uri terminate';

  @override
  String get noPausedGamesMessage => 'Niciun joc în pauză momentan.';

  @override
  String get noFinishedRunsMessage => 'Niciun run terminat momentan.';

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
  String get leaveGameTooltip => 'Părăsește jocul';

  @override
  String get scoreGridLabel => 'Grilă de scoruri';

  @override
  String get finalRoundBanner => 'Ultima rundă: un jucător a atins 10000!';

  @override
  String turnScoreLabel(int score) {
    return 'Scorul turei: $score';
  }

  @override
  String minimumRequiredLabel(int minimum) {
    return 'Minim necesar: $minimum';
  }

  @override
  String get keptDiceThisTurnLabel => 'Zaruri păstrate în această tură';

  @override
  String inheritedHandMessage(String playerName, int diceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      diceCount,
      locale: localeName,
      other: '$diceCount de zaruri',
      few: '$diceCount zaruri',
      one: '$diceCount zar',
    );
    return '$playerName moștenește $_temp0 din tura precedentă.';
  }

  @override
  String currentScoreLabel(int score) {
    return 'Scor curent: $score';
  }

  @override
  String continueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return 'Continuă cu $_temp0';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Reluarea acestei mâini ar depăși deja 10000: nu te poți opri.';

  @override
  String get restartWithFreshDiceButton => 'Reia cu 5 zaruri noi';

  @override
  String aiContinueWithDiceButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return 'Reia cu $_temp0';
  }

  @override
  String get aiRestartWithFreshDiceLabel => 'Reîncepe cu 5 zaruri noi';

  @override
  String get keepDiceButton => 'Păstrează zarurile';

  @override
  String get reRollFullHandButton => 'Aruncă din nou (zaruri fierbinți)';

  @override
  String get stopButton => 'Oprește-te';

  @override
  String get rollDiceButton => 'Aruncă zarurile';

  @override
  String diceToRollLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return '$_temp0 de aruncat';
  }

  @override
  String get bustedTitle => 'Ai ars!';

  @override
  String get bustExceedsTarget => 'Această aruncare ar depăși 10000.';

  @override
  String get continueButton => 'Continuă';

  @override
  String thisRollScoreLabel(int score) {
    return 'Scorul acestei aruncări: $score';
  }

  @override
  String get howManyFivesToKeep => 'Câte cifre de 5 păstrezi?';

  @override
  String get fullHandMustReroll =>
      'Zaruri fierbinți: trebuie să arunci din nou!';

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
  String get settingsPausedGamesTitle => 'Jocuri în pauză';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmă înainte de a șterge un joc';

  @override
  String get settingsLanguageTitle => 'Limbă';

  @override
  String get settingsLanguageSystemOption => 'Limba telefonului';

  @override
  String get diceOffTitle => 'Cine începe?';

  @override
  String get diceOffInstructions =>
      'Fiecare aruncă un zar: cel mai mic scor începe jocul.';

  @override
  String diceOffTieBreak(String names) {
    return 'Egalitate: $names aruncă din nou.';
  }

  @override
  String diceOffPlayerTurn(String playerName) {
    return '$playerName aruncă zarul';
  }

  @override
  String get diceOffRollButton => 'Aruncă zarul';

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
  String get newGameButton => 'Joc nou';

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
  String scoreProbabilityTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count de zaruri',
      few: '$count zaruri',
      one: '$count zar',
    );
    return 'Probabilitate de a marca cu $_temp0';
  }
}
