// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get splashPresents => 'apresenta';

  @override
  String get validateButton => 'Confirmar';

  @override
  String get settingsTooltip => 'Definições';

  @override
  String get helpTooltip => 'Regras do jogo';

  @override
  String get aboutTooltip => 'Sobre';

  @override
  String aboutVersionLabel(String version, String buildNumber) {
    return 'Versão $version ($buildNumber)';
  }

  @override
  String get closeButton => 'Fechar';

  @override
  String playersCountTitle(int count) {
    return 'Jogadores ($count)';
  }

  @override
  String get autoChipLabel => 'AutoRoll';

  @override
  String get startGameButton => 'Começar jogo';

  @override
  String get newGameSectionLabel => 'Nova run...';

  @override
  String get resumeGamesButton => 'Retomar jogos';

  @override
  String get managePlayersButton => 'Gerir jogadores';

  @override
  String get finishedGamesButton => 'Últimos jogos terminados';

  @override
  String get statisticsButton => 'Estatísticas';

  @override
  String playersScreenTitle(int count) {
    return 'Jogadores ($count)';
  }

  @override
  String get addPlayerTooltip => 'Adicionar um jogador';

  @override
  String get noPlayersMessage => 'Ainda não há jogadores registados.';

  @override
  String get newPlayerTitle => 'Novo jogador';

  @override
  String get editPlayerTitle => 'Editar jogador';

  @override
  String get playerNameLabel => 'Nome';

  @override
  String get playerNicknameLabel => 'Alcunha (opcional)';

  @override
  String get playerNameRequiredError => 'O nome é obrigatório.';

  @override
  String get playerNameTakenError => 'Este nome já é usado por outro jogador.';

  @override
  String get deletePlayerConfirmTitle => 'Eliminar este jogador?';

  @override
  String deletePlayerConfirmMessage(String name) {
    return 'A ficha de «$name» e as suas estatísticas serão eliminadas definitivamente. Os jogos já jogados são mantidos.';
  }

  @override
  String get statsSectionTime => 'Tempo de jogo';

  @override
  String get statsSectionGames => 'Jogos';

  @override
  String get statsSectionFigures => 'Combinações';

  @override
  String get statsSectionRolls => 'Turnos e lançamentos';

  @override
  String get statsTurns => 'Turnos jogados';

  @override
  String get statsRolls => 'Lançamentos';

  @override
  String get statsRollsPerTurn => 'Lançamentos por turno';

  @override
  String get statsSectionMisc => 'Feitos';

  @override
  String get statsTotalTime => 'Total';

  @override
  String get statsAverageTime => 'Média por jogo';

  @override
  String get statsShortestTime => 'O mais curto';

  @override
  String get statsLongestTime => 'O mais longo';

  @override
  String get statsGamesPlayed => 'Jogados';

  @override
  String get statsGamesWon => 'Ganhos';

  @override
  String get statsGamesLost => 'Perdidos';

  @override
  String get statsLoneAces => '1 isolados guardados';

  @override
  String get statsLoneFives => '5 isolados guardados';

  @override
  String get statsBrelans => 'Trios';

  @override
  String get statsCarres => 'Quadras';

  @override
  String get statsQuintes => 'Quinas';

  @override
  String get statsSuites => 'Sequências';

  @override
  String get statsSmallSuites => 'das quais baixas';

  @override
  String get statsBigSuites => 'das quais altas';

  @override
  String get statsAceQuints => 'Cinco 1';

  @override
  String get statsAceQuintsWon => 'das quais vencedoras';

  @override
  String get statsBestTurn => 'Melhor turno';

  @override
  String get statsHotDiceRun => 'Dados quentes seguidos';

  @override
  String get statsBusts => 'Rebentamentos';

  @override
  String get statsLongestBustStreak => 'série mais longa';

  @override
  String get statsSelfBars => 'Auto-riscados';

  @override
  String get statsBarsInflicted => 'Riscados a outros';

  @override
  String get scoreChartTitle => 'Evolução das pontuações';

  @override
  String get gameStatsTitle => 'Estatísticas do jogo';

  @override
  String get gameStatsGameSection => 'Jogo';

  @override
  String get gameStatsFiguresSection => 'Combinações do jogo';

  @override
  String get gameStatsDuration => 'Tempo de jogo';

  @override
  String gameStatsPlayerSummary(int turns, int best, int busts) {
    String _temp0 = intl.Intl.pluralLogic(
      turns,
      locale: localeName,
      other: '$turns turnos',
      one: '$turns turno',
    );
    String _temp1 = intl.Intl.pluralLogic(
      busts,
      locale: localeName,
      other: '$busts rebentamentos',
      one: '$busts rebentamento',
    );
    return '$_temp0 · melhor $best · $_temp1';
  }

  @override
  String statsPlayerSummary(int games, int won, int best) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games jogos',
      one: '$games jogo',
    );
    String _temp1 = intl.Intl.pluralLogic(
      won,
      locale: localeName,
      other: '$won ganhos',
      one: '$won ganho',
    );
    return '$_temp0 · $_temp1 · melhor $best';
  }

  @override
  String get scoreChartEmpty =>
      'Ainda nenhum turno terminado: ainda não há nada para traçar.';

  @override
  String get replayUnavailable =>
      'Este jogo não pode ser revisto: o seu registo está incompleto.';

  @override
  String get replayPlay => 'Reproduzir';

  @override
  String get replayPause => 'Pausa';

  @override
  String replayTurnOf(int turn, int count) {
    return '$turn / $count';
  }

  @override
  String scoreChartTurn(int turn) {
    return 'Turno $turn';
  }

  @override
  String get scoreChartXAxis => 'Turnos jogados';

  @override
  String get statsBreakdownRow => 'dos quais';

  @override
  String get statsRecordsTitle => 'Recordes';

  @override
  String get statsNoRecordYet => 'Ainda não há recordes.';

  @override
  String statsValueWithHolder(String value, String holders) {
    return '$value — $holders';
  }

  @override
  String get pickPlayersTitle => 'Escolher jogadores';

  @override
  String get addHumanTooltip => 'Adicionar um jogador';

  @override
  String get addBotTooltip => 'Adicionar um bot';

  @override
  String get createPlayerButton => 'Novo jogador';

  @override
  String get noPlayersToPickMessage =>
      'Não há jogadores registados. Cria um para começar.';

  @override
  String get botLabel => 'Bot';

  @override
  String get removeSeatTooltip => 'Retirar do jogo';

  @override
  String get notEnoughPlayersMessage =>
      'São precisos pelo menos dois jogadores.';

  @override
  String playerGamesSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jogos jogados',
      one: '$count jogo jogado',
      zero: 'Nenhum jogo jogado',
    );
    return '$_temp0';
  }

  @override
  String pausedGamesSectionLabel(int count) {
    return 'Runs interrompidas ($count)';
  }

  @override
  String finishedRunsSectionLabel(int count) {
    return 'Runs terminadas ($count)';
  }

  @override
  String get noPausedGamesMessage => 'Ainda não há jogos em pausa.';

  @override
  String get noFinishedRunsMessage => 'Ainda não há runs terminadas.';

  @override
  String get gameRunParticipantsSeparator => ' vs ';

  @override
  String get deleteGameConfirmTitle => 'Eliminar este jogo?';

  @override
  String deleteGameConfirmMessage(String alias) {
    return 'O jogo «$alias» será eliminado definitivamente.';
  }

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get resumeLastGameDialogTitle => 'Retomar o jogo?';

  @override
  String resumeLastGameDialogMessage(String alias) {
    return 'Há um jogo «$alias» em curso. Queres retomá-lo?';
  }

  @override
  String get resumeGameButton => 'Retomar';

  @override
  String get gameOverReplayButton => 'Rever o jogo';

  @override
  String get scoreGridLabel => 'Tabela de pontuações';

  @override
  String get finalRoundBanner => 'Última ronda: um jogador atingiu 10000!';

  @override
  String get currentRollZoneLabel => 'Pista';

  @override
  String currentRollZoneLabelWithScore(int points) {
    return 'Pista ($points)';
  }

  @override
  String get currentHandZoneLabel => 'Mão atual';

  @override
  String get logHotDiceMessage => 'Dados quentes!';

  @override
  String rollButtonHotDiceTotal(int total) {
    return 'Dados quentes! → $total';
  }

  @override
  String get logScoreCollisionMessage => 'Pontuação riscada:';

  @override
  String logRollGainMessage(String kept, int gain, int count, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return '$kept: $gain, $_temp0 => $total pts';
  }

  @override
  String logRollGainHotDiceMessage(String kept, int gain, int total) {
    return '$kept: $gain, dados quentes => $total pts';
  }

  @override
  String logBankedMessage(int score, int total) {
    return '$score pts arrecadados => $total pts';
  }

  @override
  String logResumedHandMessage(int score) {
    return '$score pts retomados';
  }

  @override
  String logBustMessage(int lost) {
    return '$lost: Rebentou!';
  }

  @override
  String logBustTiretMessage(int lost, int score) {
    return '$lost: Rebentou! => $score traço';
  }

  @override
  String logBustBarredPrefix(int lost) {
    return '$lost: Rebentou! =>';
  }

  @override
  String logBustBarredReturnMessage(int score) {
    return 'volta a $score';
  }

  @override
  String get inheritedHandExceedsWinning =>
      'Retomar esta mão já ultrapassaria 10000: não é possível parar.';

  @override
  String get rollButton => 'Lançar';

  @override
  String get showProbabilitiesSetting => 'Mostrar probabilidades';

  @override
  String get showProbabilitiesSettingSubtitle =>
      'Mostra no botão «Lançar» a probabilidade de marcar pelo menos um ponto';

  @override
  String get stopButton => 'Parar';

  @override
  String get bustedTitle => 'Rebentou!';

  @override
  String get bustExceedsTarget => 'Esta jogada ultrapassaria 10000.';

  @override
  String get bustFullHandAtTarget =>
      'Dados quentes em 10000: não é possível parar, e relançar tudo ultrapassaria.';

  @override
  String get bustContinueButton => 'Continuar';

  @override
  String get inheritedHandDialogTitle => 'Retomar?';

  @override
  String inheritedHandDialogMessage(int score, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dados',
      one: '$count dado',
    );
    return '$score, $_temp0';
  }

  @override
  String get resumeHandButton => 'Retomar a mão';

  @override
  String get newHandButton => 'Nova mão';

  @override
  String get failureBelowMinimum => 'Pontuação insuficiente para parar.';

  @override
  String get failureEndsIn50 =>
      'Não podes parar com uma pontuação que termine em 50.';

  @override
  String get failureMustContinueHotDice => 'Tens de relançar.';

  @override
  String get failureMustContinueFinalRound =>
      'Não podes parar: a última ronda exige atingir exatamente 10000.';

  @override
  String get failureNotRolledYet =>
      'Tens de lançar os dados antes de poderes parar.';

  @override
  String get failureWouldMakeWinningImpossible =>
      'Parar agora tornaria impossível chegar exatamente a 10000.';

  @override
  String get settingsDelaysTitle => 'Temporizações';

  @override
  String get settingsDelaysDescription =>
      'Atraso antes de uma ação automática se ativar sozinha. 0 para desativar.';

  @override
  String get settingsAiDelayLabel => 'Mensagens da IA (ms)';

  @override
  String get settingsAutoActionDelayLabel =>
      'Ações automáticas do jogador humano (ms)';

  @override
  String get settingsDiceTitle => 'Dados';

  @override
  String get settingsDiceUniform => 'Uniforme';

  @override
  String get settingsDiceVaried => 'Variado';

  @override
  String get settingsSoundsTitle => 'Som';

  @override
  String get settingsMusicLabel => 'Música de fundo';

  @override
  String get settingsSoundEffectsLabel => 'Efeitos sonoros';

  @override
  String get settingsHandednessLabel => 'Disposição dos botões';

  @override
  String get settingsHandednessRight => 'Destro';

  @override
  String get settingsHandednessLeft => 'Canhoto';

  @override
  String get settingsControlsTitle => 'Controlos';

  @override
  String get settingsShakeToRollLabel => 'Agitar para lançar os dados';

  @override
  String get settingsPausedGamesTitle => 'Jogos em pausa';

  @override
  String get settingsConfirmBeforeDeleteGameLabel =>
      'Confirmar antes de eliminar um jogo';

  @override
  String get settingsLanguageTitle => 'Idioma';

  @override
  String get settingsLanguageSystemOption => 'Idioma do telemóvel';

  @override
  String get reorderPlayersHint =>
      'Arraste um jogador pela alça para mudar a ordem à volta da mesa.';

  @override
  String get reorderPlayerHandleLabel => 'Mover este jogador';

  @override
  String get diceOffTitle => 'Quem começa?';

  @override
  String get diceOffInstructions =>
      'Todos lançam o dado ao mesmo tempo: começa o mais baixo. Em caso de empate, os empatados lançam de novo.';

  @override
  String diceOffTieBreak(String names) {
    return 'Empate: $names relançam.';
  }

  @override
  String diceOffWinnerAnnouncement(String playerName) {
    return '$playerName começa o jogo!';
  }

  @override
  String get gameOverTitle => 'Fim do jogo';

  @override
  String winnerAnnouncement(String playerName) {
    return '$playerName vence!';
  }

  @override
  String playerScoreLine(String name, int score) {
    return '$name: $score';
  }

  @override
  String get passDeviceInstruction => 'Passa o aparelho a';

  @override
  String get readyButton => 'Pronto';

  @override
  String get notEnteredLabel => '(não entrou)';

  @override
  String get opportunityTooltip =>
      'A 200 pontos de riscar o jogador logo acima!';

  @override
  String get dangerTooltip =>
      'Perigo: o jogador logo abaixo está a apenas 200 pontos, risco de te riscar';

  @override
  String get tiretTooltip => 'Traço: um segundo rebentamento risca a pontuação';

  @override
  String get radarTargetsTooltip =>
      'Pontuações que a mão em curso poderia riscar';

  @override
  String get radarGapTooltip => 'Diferença para o total da mão em curso';

  @override
  String get previousScoreHadTiretTooltip =>
      'A pontuação anterior tinha um traço';

  @override
  String get rankFirstTooltip => 'Na liderança';

  @override
  String get rankSecondTooltip => '2.º em pontuação';

  @override
  String get rankThirdTooltip => '3.º em pontuação';

  @override
  String get rulesScreenTitle => 'Regras do jogo';

  @override
  String get tutorialTitle => 'Tutorial';

  @override
  String get tutorialSkip => 'Saltar';

  @override
  String get tutorialFinalOutro =>
      'O bot ficou riscado e agora tem de tentar os 10 000. Já conheces todas as regras: bom jogo!';

  @override
  String get tutorialFinalExact =>
      'Três 4: 10 000 certos! É registado automaticamente.';

  @override
  String get tutorialFinalNoStop =>
      '100: 9600. Na ronda final não se pode parar: relança.';

  @override
  String get tutorialFinalIntro =>
      'O bot atingiu 10 000: é a ronda final. Para ganhar é preciso igualá-lo, o que o risca. Parar antes é proibido.';

  @override
  String get tutorialCollisionOutro =>
      'O bot fica riscado e volta a 1500. Atingir uma linha de outro jogador, mesmo antiga, também a risca.';

  @override
  String get tutorialCollisionCollide =>
      'Dois 1: 200. Ficarias com 2000, a pontuação do bot, a vermelho no radar dele. Para para o riscar.';

  @override
  String get tutorialCollisionIntro =>
      'Na linha do bot, o radar mostra as pontuações dele que poderias riscar: atingir o mesmo total fá-lo recuar.';

  @override
  String get tutorialInheritOutro =>
      'Depois de um rebentamento recomeça-se sempre com 5 dados novos. Nunca se propõe uma mão que já não se poderia registar.';

  @override
  String get tutorialInheritStop => 'Um 1: a mão vale 1100. Para.';

  @override
  String get tutorialInheritTake =>
      'O bot parou nos 1000 deixando 2 dados. Retoma a mão: partes dos 1000 pontos dele, e os 2 dados são lançados logo (lança-se sempre pelo menos uma vez antes de parar).';

  @override
  String get tutorialInheritIntro =>
      'Quando um jogador para deixando dados, o seguinte pode retomá-los, com os pontos dele como base.';

  @override
  String get tutorialExtensionOutro =>
      'A extensão vale para todo o turno, até para um 5 (100 em vez de 50), e apaga-se com os dados quentes.';

  @override
  String get tutorialExtensionExtended =>
      'Um 2 sozinho não vale nada… exceto aqui: depois do teu trio de 2, vale 100 (a vermelho). A mão soma 300: para.';

  @override
  String get tutorialExtensionBrelan =>
      'Três 2: 200. Relança os 2 últimos dados.';

  @override
  String get tutorialExtensionIntro =>
      'Depois de um trio de um valor, um dado sozinho do mesmo valor, mais tarde no turno, vale 100 pontos.';

  @override
  String get tutorialBustOutro =>
      'Um rebentamento marca a linha com um traço; um segundo risca-a. Com 0, um rebentamento não custa nada.';

  @override
  String get tutorialBustBarred =>
      'Segundo rebentamento: a linha de 1500 fica riscada, voltas a 500, a tua pontuação anterior. Toca em ✓.';

  @override
  String get tutorialBustRollAgain =>
      'A tua linha tem um traço: um segundo rebentamento riscá-la-ia. Lança mesmo assim.';

  @override
  String get tutorialBustTiret =>
      'Rebentou! A mão perde-se, e a tua linha de 1500 recebe um traço. Toca em ✓.';

  @override
  String get tutorialBustIntro =>
      'Um lançamento que não pontua é um rebentamento: a mão em curso perde-se. Tens 1500 pontos.';

  @override
  String get tutorialHotDiceOutro =>
      'Lembra-te: nunca parar num total que termine em 50, e os dados quentes relançam-se sempre.';

  @override
  String get tutorialHotDiceStop =>
      '500: chega para entrar, e sem 50 no fim. Para.';

  @override
  String get tutorialHotDiceFives =>
      'Dois 5, mas opcionais: este seletor escolhe quantos manter. Com os dois, 550 terminaria em 50: não poderias parar. Escolhe 1.';

  @override
  String get tutorialHotDiceFullHand =>
      'Três 3: 300, a mão sobe para 450. Todos os dados pontuaram: dados quentes! O botão mostra o total que terias; relançam-se os 5 dados, sem poder parar.';

  @override
  String get tutorialHotDiceKept =>
      'O 1 e o 5 ficam guardados: a mão vale 150. Relança os outros 3 dados.';

  @override
  String get tutorialHotDiceIntro =>
      'Quando todos os dados pontuam são dados quentes: relançam-se os 5. E um 5 sozinho às vezes é opcional.';

  @override
  String get tutorialBasicsOutro =>
      '700 pontos registados: estás no jogo! A partir de agora, cada turno tem de render pelo menos 200 pontos.';

  @override
  String get tutorialBasicsBrelan =>
      'Três 6: um trio vale 100 vezes o seu valor, aqui 600 (três 1: 1000). A mão vale 700, chega para entrar: toca na mão para parar.';

  @override
  String get tutorialBasicsAce =>
      'Sozinhos, só pontuam o 1 (100) e o 5 (50): o 1 fica de lado. Para entrar no jogo são precisos 500 pontos num turno: relança os outros 4 dados.';

  @override
  String get tutorialBasicsIntro =>
      'Bem-vindo ao Le 10000! O objetivo: atingir exatamente 10 000 pontos. Em cada turno lançam-se 5 dados e põem-se de lado os que pontuam.';

  @override
  String get tutorialLessonFinalRound => 'A ronda final';

  @override
  String get tutorialLessonCollision => 'Riscar um jogador';

  @override
  String get tutorialLessonInheritedHand => 'A mão herdada';

  @override
  String get tutorialLessonExtension => 'A regra da extensão';

  @override
  String get tutorialLessonBust => 'O rebentamento';

  @override
  String get tutorialLessonHotDice => 'Dados quentes';

  @override
  String get tutorialLessonBasics => 'O básico';

  @override
  String get tutorialBotTurn => 'Vez do bot: joga sozinho.';

  @override
  String get tutorialRollPrompt => 'Toca no botão de lançar.';

  @override
  String get tutorialWholePath => 'Todo o tutorial';

  @override
  String get tutorialLessonsTitle => 'Lições do tutorial';

  @override
  String get tutorialNextLesson => 'Lição seguinte';

  @override
  String tutorialLessonCounter(int number, int total, String title) {
    return 'Lição $number/$total: $title';
  }

  @override
  String get tutorialPlayerName => 'Tu';

  @override
  String get tutorialNext => 'Seguinte';

  @override
  String get tutorialFinish => 'Começar a jogar';

  @override
  String get tutorialReplayButton => 'Lições do tutorial';

  @override
  String get rulesGoalTitle => 'Objetivo do jogo';

  @override
  String get rulesGoalBody =>
      'Atingir exatamente 10 000 pontos. Ultrapassar não conta.';

  @override
  String get rulesTurnTitle => 'Como se joga um turno';

  @override
  String get rulesTurnBody =>
      'Lanças 5 dados, pões de lado pelo menos um dado que pontue e depois relanças os restantes ou paras e registas. Se um lançamento não der nada, é um rebentamento: perdes tudo o que acumulaste neste turno.';

  @override
  String get rulesScoringTitle => 'O que dá pontos';

  @override
  String get rulesScoringBody =>
      '• Um 1 isolado: 100 pontos. Um 5 isolado: 50 pontos. Os outros valores isolados (2, 3, 4, 6) não dão nada.\n• Uma trinca: o valor do dado × 100 (três 6 valem 600), exceto três 1, que valem 1000.\n• Uma quadra: mais 1000 pontos do que a trinca correspondente (quatro 6 valem 1600, quatro 1 valem 2000).\n• Cinco dados iguais valem o valor do dado × 1000. Cinco 1 dão diretamente 10 000 pontos: a vitória imediata.\n• Uma sequência de 5 dados seguidos (1-2-3-4-5 ou 2-3-4-5-6) vale 500 pontos.';

  @override
  String get rulesBustTitle => 'Rebentamento e riscado';

  @override
  String get rulesBustBody =>
      'Um rebentamento põe um traço na tua linha de pontuação atual. Se já tinha um, a linha é riscada e voltas à pontuação anterior. Se atingires o mesmo total de outro jogador, é ele que fica riscado.';

  @override
  String get rulesEntryTitle => 'Parar';

  @override
  String get rulesEntryBody =>
      '• São precisos pelo menos 500 pontos para entrar no jogo e, depois, pelo menos 200 por turno.\n• Nunca podes parar com um total de turno que termine em 50 (250, 450…).\n• Se todos os teus dados pontuarem («dados quentes»), tens de relançar os 5.';

  @override
  String get rulesExtensionTitle => 'A regra da extensão';

  @override
  String get rulesExtensionBody =>
      'Depois de registares uma trinca ou uma quadra, qualquer dado isolado do mesmo valor mais tarde no turno vale 100, incluindo um 5. Desaparece com os dados quentes.';

  @override
  String get rulesInheritTitle => 'Herdar os dados do jogador anterior';

  @override
  String get rulesInheritBody =>
      'Se paras com dados por lançar, o jogador seguinte pode ficar com esses dados e com a tua pontuação como base, ou recomeçar com 5 dados novos. Depois de um rebentamento, recomeça sempre com 5 dados novos.';

  @override
  String get rulesVictoryTitle => '10 000 exatos e ronda final';

  @override
  String get rulesVictoryBody =>
      'Assim que um lançamento permite atingir exatamente 10 000, a tomada é automática e o turno termina. Os outros jogadores têm então um último turno para igualar essa pontuação: nele ninguém pode parar abaixo de 10 000, é preciso igualá-la ou rebentar. Se outro jogador também atingir exatamente 10 000, risca o primeiro e começa uma nova ronda final à sua volta.\nCaso particular: uma mão cheia que cai exatamente em 10 000 é um rebentamento, porque obriga a relançar. Só a quina de ases ganha.';

  @override
  String get onlinePlayButton => 'Jogar online';

  @override
  String get onlineResumeButton => 'Retomar o jogo online';

  @override
  String get onlineTitle => 'Jogo online';

  @override
  String get onlineCreateButton => 'Criar uma sala';

  @override
  String get onlineJoinButton => 'Entrar';

  @override
  String get onlineCodeLabel => 'Código da sala';

  @override
  String get onlineOrDivider => 'ou';

  @override
  String get onlineShareHint =>
      'Dê este código aos outros jogadores para que se juntem a si.';

  @override
  String get onlineShareButton => 'Partilhar o código';

  @override
  String onlineShareMessage(String code, String link) {
    return 'Junte-se ao meu jogo online de Le 10000! Código da sala: $code\n$link';
  }

  @override
  String onlinePlayersHeader(int count, int max) {
    return 'Jogadores ($count/$max)';
  }

  @override
  String get onlineHostBadge => 'Anfitrião';

  @override
  String get onlineDisconnectedBadge => 'Desligado';

  @override
  String get onlineNeedTwoPlayers =>
      'São precisos pelo menos 2 jogadores, todos ligados.';

  @override
  String get onlineWaitingForHost => 'A aguardar que o anfitrião comece…';

  @override
  String get onlineLeaveButton => 'Sair';

  @override
  String get onlineLeaveConfirmTitle => 'Sair do jogo online?';

  @override
  String get onlineLeaveConfirmBody =>
      'Num jogo já começado, o seu lugar ficará vazio e o jogo aguardará o seu regresso.';

  @override
  String get onlineLeaveGameBody =>
      'Vais sair da sala: um bot jogará no teu lugar até ao fim do jogo.';

  @override
  String get onlineDiceOffWaitingStart => 'À espera do início do jogo';

  @override
  String get logPlayerReplacedByBot => 'saiu do jogo: um bot joga no seu lugar';

  @override
  String get botSeatTooltip => 'Jogado por um bot (jogador saiu)';

  @override
  String get rematchButton => 'Jogar outra vez';

  @override
  String rematchProposal(String name) {
    return '$name propõe uma desforra';
  }

  @override
  String get rematchWaiting => 'À espera dos outros jogadores…';

  @override
  String rematchSecondsLeft(int seconds) {
    return '$seconds s';
  }

  @override
  String get rematchAccept => 'Aceitar';

  @override
  String get rematchRefuse => 'Recusar';

  @override
  String get rematchExcludedNotice =>
      'Saíste da sala: não há desforra para ti.';

  @override
  String get rematchCancelledNotice =>
      'Não há desforra: são precisos pelo menos dois jogadores.';

  @override
  String get onlineConnecting => 'A ligar ao servidor…';

  @override
  String get onlineReconnecting => 'Ligação perdida, a religar…';

  @override
  String get onlineSuspended =>
      'Jogo suspenso: um jogador está ausente há demasiado tempo.';

  @override
  String onlineWaitingFor(String playerName) {
    return '$playerName está a jogar…';
  }

  @override
  String get onlineDiceOffContinue => 'Jogar';

  @override
  String get onlineErrorUnreachable => 'Servidor inacessível.';

  @override
  String get onlineErrorRoomNotFound =>
      'Não existe nenhuma sala com este código.';

  @override
  String get onlineErrorRoomFull => 'Esta sala está cheia.';

  @override
  String get onlineErrorGameStarted => 'Este jogo já começou.';

  @override
  String get onlineErrorRateLimited =>
      'Demasiadas tentativas: tente novamente dentro de instantes.';

  @override
  String get onlineErrorBadToken => 'O seu lugar nesta sala já não existe.';

  @override
  String get onlineErrorUnsupportedVersion =>
      'Atualize a aplicação para jogar online.';

  @override
  String get onlineErrorGeneric => 'Ocorreu um erro.';

  @override
  String get myProfileTitle => 'O meu perfil';

  @override
  String get myProfileWelcomeTitle => 'Bem-vindo!';

  @override
  String get myProfileWelcomeMessage =>
      'Crie o seu perfil: o seu nome, uma alcunha se quiser, e a mão com que joga. Online, os outros jogadores verão a sua alcunha, ou o seu nome se não tiver alcunha.';

  @override
  String get myProfileExistingPrompt =>
      'Já está na lista de jogadores? Toque no seu nome.';

  @override
  String get myProfileCreateButton => 'Criar o meu perfil';

  @override
  String get myProfileEditButton => 'Editar o meu perfil';

  @override
  String get myProfileBadge => 'Eu';

  @override
  String onlinePlayingAs(String name) {
    return 'Joga como «$name»';
  }

  @override
  String get onlineNameInvalidError =>
      'Online, a sua alcunha (ou o seu nome) deve ter no máximo 20 caracteres, sem caracteres invisíveis.';

  @override
  String get settingsDiceSoundLabel => 'Som dos dados';

  @override
  String get settingsDiceSoundRealistic => 'Realista';

  @override
  String get settingsDiceSoundSynthetic => 'Sintético';

  @override
  String get homeChipsHint => 'Mantenha premida uma ficha para ver o nome.';

  @override
  String get emoteThoughtful => 'Pensativo';

  @override
  String get emoteMocking => 'Morto de rir';

  @override
  String get emoteDevastated => 'Arrasado';

  @override
  String get emoteJoyful => 'Abraço';

  @override
  String get emotePhraseCoincidence => 'Que coincidência...';

  @override
  String get emotePhraseStickyFive => 'Aquele cinco não descola!';

  @override
  String get emotePhraseFullHandEmptyHand => 'Mão cheia, mão vazia!';

  @override
  String get emotePhraseNeverTakeA1000 => 'Nunca se retoma um 1000!';

  @override
  String get emotePhraseNoWay => 'Simplesmente impossível!';

  @override
  String get emotePhraseArgh => 'Aaaaaargh!';

  @override
  String get emotePhraseHello => 'Olá!';

  @override
  String get emotePhraseYes => 'Sim!';

  @override
  String get emotePhraseTooGreedy => 'A gula é um feio defeito!';

  @override
  String get emotePhraseTooLucky => 'Um pouco de sorte a mais...';

  @override
  String get emotePhraseDryTenThousand => 'Direto aos 10000';

  @override
  String get emotePhraseLucky => 'Seu sortudo!';

  @override
  String get emotePhraseGoodLuck => 'Boa sorte!';

  @override
  String get emotePhraseThanks => 'Obrigado';

  @override
  String get emotePhraseSorryMustGo => 'Desculpem, mas tenho de ir';

  @override
  String get emoteAngry => 'Zangado';

  @override
  String get emoteRelieved => 'Aliviado';

  @override
  String get emotePhraseStrangeChoice => 'Mas que escolha estranha é esta?';

  @override
  String get emotePhraseAllByFives => 'Tudo pelos cincos!';

  @override
  String get emotePhraseWithPanache => 'Com estilo!';

  @override
  String get emotePhraseUnfair => 'Isto é mesmo muito injusto';

  @override
  String get emotePhrasePhew => 'Ufa!';

  @override
  String get emotePhraseAtLast => 'Finalmente!';

  @override
  String get emotePhraseCloseCall => 'Foi por pouco!';

  @override
  String get emotePhraseWellPlayed => 'Bem jogado';

  @override
  String get emotePhraseSorry => 'Desculpa';

  @override
  String get gameHistoryBar => 'Histórico';

  @override
  String updateAvailableMessage(String version, int build) {
    return 'Uma nova versão está disponível ($version, build $build).';
  }

  @override
  String get updateNowButton => 'Atualizar';

  @override
  String get updateLaterButton => 'Mais tarde';
}
