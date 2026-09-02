import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/combination.dart';
import '../../game/game_engine.dart';
import '../../game/game_recording.dart';
import '../../game/player.dart';
import '../../game/turn_result.dart';
import '../../game/turn_state.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/game_providers.dart';
import '../../state/replay_speed_provider.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import '../sound_effects.dart';
import '../widgets/app_title.dart';
import '../widgets/bordered_section.dart';
import '../widgets/die_widget.dart';
import '../widgets/player_avatar.dart';
import '../widgets/replay_speed_control.dart';
import '../widgets/score_sheet.dart';
import 'game_over_screen.dart';
import 'pass_device_screen.dart';
import 'score_grid_screen.dart';

/// Détermine l'état visuel de chaque dé d'un lancer, en tenant compte du
/// nombre de 5 que le joueur envisage de garder (aperçu avant validation).
List<DieVisualState> _classifyDiceForDisplay(RollAnalysis analysis, int selectedKeepCount) {
  if (analysis.groups.any((g) => g.isSuite)) {
    return List.filled(analysis.faces.length, DieVisualState.kept);
  }

  final mandatoryRemaining = <int, int>{};
  for (final g in analysis.mandatoryGroups) {
    mandatoryRemaining[g.value] = (mandatoryRemaining[g.value] ?? 0) + g.diceCount;
  }

  final fives = analysis.declinableFives;
  var keepRemaining = selectedKeepCount;

  return [
    for (final v in analysis.faces)
      if ((mandatoryRemaining[v] ?? 0) > 0)
        _consume(mandatoryRemaining, v, _mandatoryVisualState(analysis, v))
      else if (fives != null && v == 5)
        (() {
          if (keepRemaining > 0) {
            keepRemaining--;
            final perDie = fives.points ~/ fives.diceCount;
            return perDie == 100 ? DieVisualState.extended : DieVisualState.kept;
          }
          return DieVisualState.declined;
        })()
      else
        DieVisualState.junk,
  ];
}

DieVisualState _mandatoryVisualState(RollAnalysis analysis, int value) {
  final g = analysis.mandatoryGroups.firstWhere((g) => g.value == value);
  // Un groupe obligatoire isolé (moins de 3 dés) de valeur non-as ne peut
  // exister que via la règle d'extension : ses points sont "temporaires".
  final isExtended = g.diceCount < 3 && g.value != 1;
  return isExtended ? DieVisualState.extended : DieVisualState.kept;
}

DieVisualState _consume(Map<int, int> remaining, int value, DieVisualState result) {
  remaining[value] = remaining[value]! - 1;
  return result;
}

/// Vrai s'il existe un choix réel sur le nombre de 5 à garder (plusieurs
/// valeurs possibles), pas juste une case techniquement "déclinable" dont la
/// seule valeur légale serait de tout garder.
bool _hasRealChoice(RollAnalysis analysis) {
  final fives = analysis.declinableFives;
  if (fives == null || !analysis.canDeclineFives) return false;
  final minKeep = analysis.mandatoryGroups.isEmpty ? 1 : 0;
  return fives.diceCount > minKeep;
}

/// Détermine, parmi les choix légaux de nombre de 5 à garder, le meilleur
/// par défaut : le score de tour résultant le plus élevé, en évitant si
/// possible qu'il ne finisse par 50 (score sur lequel il est interdit de
/// s'arrêter volontairement) — le joueur reste libre d'ajuster ensuite via
/// les ChoiceChip (certains préfèrent délibérément garder moins de 5).
/// Repli sur le score le plus élevé si toutes les options finissent par 50
/// (possible seulement via la règle d'extension, où chaque 5 vaut 100 : le
/// dernier chiffre ne varie alors jamais avec le nombre gardé).
int _defaultKeepCount(TurnState turn, RollAnalysis analysis) {
  final fives = analysis.declinableFives;
  if (fives == null) return 0;
  final minKeep = analysis.mandatoryGroups.isEmpty ? 1 : 0;
  final maxKeep = fives.diceCount;
  for (var keep = maxKeep; keep >= minKeep; keep--) {
    final hypothetical = applyKeepDecision(turn, declineFivesCount: maxKeep - keep);
    if (hypothetical.bankedScore % 100 != 50) return keep;
  }
  return maxKeep;
}

/// Points que rapporterait ce lancer si le joueur valide sa sélection
/// actuelle (combien de 5 garder).
int _previewPoints(RollAnalysis analysis, int selectedKeepCount) {
  var points = analysis.mandatoryGroups.fold<int>(0, (sum, g) => sum + g.points);
  final fives = analysis.declinableFives;
  if (fives != null) {
    final perDie = fives.points ~/ fives.diceCount;
    points += selectedKeepCount * perDie;
  }
  return points;
}

/// Décrit en français un groupe scorant pour le journal de partie (ex.
/// "brelan de 3", "2 as", "suite"). Les 1 et 5 isolés se nomment "as"/"cinq" ;
/// un groupe isolé d'une autre valeur (2/3/4/6) ne peut exister que via la
/// règle d'extension — rare, décrit par sa valeur brute en repli.
String _describeGroup(ScoringGroup g) {
  if (g.isSuite) return 'suite';
  if (g.diceCount >= 3) {
    final name = switch (g.diceCount) { 3 => 'brelan', 4 => 'carré', _ => 'quinte' };
    return g.value == 1 ? "$name d'as" : '$name de ${g.value}';
  }
  final noun = switch (g.value) { 1 => 'as', 5 => 'cinq', _ => '${g.value}' };
  return '${g.diceCount} $noun';
}

/// Reconstruit l'annonce du score d'un lancer résolu (ex. "2 as et brelan de
/// 3 => 500") à partir de son analyse et des points effectivement marqués —
/// sans rejouer la décision de garde : le nombre de 5 gardés se déduit par
/// arithmétique (roundPoints moins les groupes obligatoires, divisé par la
/// valeur d'un 5), pas besoin de connaître `declineFivesCount`. Fonctionne
/// donc identiquement pour un humain, une IA, et le mode rejeu.
String _describeRollResult(RollAnalysis analysis, int roundPoints) {
  final parts = [for (final g in analysis.mandatoryGroups) _describeGroup(g)];
  final fives = analysis.declinableFives;
  if (fives != null) {
    final mandatoryPoints = analysis.mandatoryGroups.fold<int>(0, (sum, g) => sum + g.points);
    final perDie = fives.points ~/ fives.diceCount;
    final keptFives = (roundPoints - mandatoryPoints) ~/ perDie;
    if (keptFives > 0) {
      parts.add(_describeGroup(ScoringGroup(value: 5, diceCount: keptFives, points: keptFives * perDie)));
    }
  }
  return '${parts.join(' et ')} => $roundPoints';
}

/// Une entrée horodatée du journal de partie (voir [_GameScreenState._log]),
/// rattachée au joueur concerné (pour son blason, voir [PlayerAvatarWidget]).
class _LogEntry {
  final DateTime timestamp;
  final String playerName;
  final String text;
  const _LogEntry(this.timestamp, this.playerName, this.text);
}

String _formatLogDate(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year}';

String _formatLogTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

/// Dérive 0 à N entrées de journal pour la transition [previous] -> [next]
/// (un pas de la partie principale, humain, IA ou rejoué) : pure fonction
/// d'état, sans dépendance à comment cette transition a été obtenue — utilisée
/// aussi bien pour le suivi en direct (voir `ref.listen` dans `build()`) que
/// pour reconstruire tout l'historique d'une partie reprise (voir
/// `_seedLogFromHistory`, qui rejoue `GameNotifier.actions` depuis zéro).
///
/// [includeBust] contrôle si un craque fraîchement détecté génère lui-même
/// son entrée ici : en direct, le craque est plutôt logué au moment de sa
/// révélation visuelle (voir `_scheduleBustRevealIfNeeded`), pour rester
/// synchrone avec le suspense déjà à l'écran — mais lors d'une reconstruction
/// d'historique, il n'y a pas d'animation à attendre, donc `true`.
List<_LogEntry> _logEntriesForStep(
  GameEngine? previous,
  GameEngine next, {
  required AppLocalizations l10n,
  required DateTime at,
  required bool includeBust,
}) {
  final nextTurn = next.activeTurn;
  if (nextTurn == null) return const [];
  final prevTurn = previous?.activeTurn;
  final playerName = next.currentPlayer.name;
  final entries = <_LogEntry>[];

  // Un tour tout juste démarré (encore aucun lancer effectué) : annonce le
  // nombre de dés à lancer. `!hasRolledThisTurn` est un marqueur exclusif —
  // il ne redevient jamais vrai une fois passé à faux pour ce tour — donc ce
  // test seul suffit à détecter l'entrée dans cet état, quelle que soit son
  // origine (nouvelle partie, après un craque, main héritée acceptée...).
  if (!nextTurn.busted && nextTurn.pendingRoll == null && !nextTurn.hasRolledThisTurn) {
    entries.add(_LogEntry(at, playerName, l10n.diceToRollLabel(nextTurn.diceToRoll)));
  }

  // Une décision de garde vient d'être appliquée sur le lancer précédent
  // (`prevTurn!.busted` exclut un `prevTurn` qui serait un craque déjà
  // révolu dont le `pendingRoll` traînerait encore — jamais un vrai choix).
  if (prevTurn?.pendingRoll != null &&
      !prevTurn!.busted &&
      nextTurn.pendingRoll == null &&
      !nextTurn.busted) {
    final analysis = prevTurn.pendingRoll!;
    final roundPoints = nextTurn.bankedScore - prevTurn.bankedScore;
    entries.add(_LogEntry(at, playerName, _describeRollResult(analysis, roundPoints)));
    if (nextTurn.mustContinue) {
      entries.add(_LogEntry(at, playerName, l10n.logHotDiceMessage));
    } else {
      entries.add(_LogEntry(at, playerName, l10n.diceToRollLabel(nextTurn.diceToRoll)));
    }
  }

  if (includeBust && nextTurn.busted && !(prevTurn?.busted ?? false)) {
    entries.add(_LogEntry(at, playerName, l10n.bustedTitle));
  }

  return entries;
}

/// [replayMode] : rejeu spectateur d'un run archivé (voir
/// `GameNotifier.startGameReplay`) — écran entièrement inerte
/// (`AbsorbPointer`), avance seul (vitesse x1/x2/x4, [ReplaySpeedControl])
/// au lieu d'attendre une décision IA/humaine, jusqu'à l'écran de victoire.
class GameScreen extends ConsumerStatefulWidget {
  final bool replayMode;

  const GameScreen({super.key, this.replayMode = false});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  /// Combien de 5 déclinables le joueur choisit de garder (par défaut, tous).
  int _selectedKeep = 0;

  Timer? _pendingTimer;
  VoidCallback? _pendingAction;

  /// Journal de partie : horodaté, affiché du plus récent au plus ancien
  /// (voir [_buildGameLog]). Rempli au montage par rejeu de l'historique déjà
  /// persisté (voir [_seedLogFromHistory]), puis tenu à jour en direct par
  /// comparaison d'état (voir [_logEntriesForStep], appelée depuis
  /// `ref.listen` dans `build()`) — état local à l'écran, jamais écrit dans
  /// [GameNotifier] : dérivé du même journal d'actions que celui déjà
  /// persisté dans le `.run`, pas dupliqué.
  final List<_LogEntry> _log = [];
  final ScrollController _logScrollController = ScrollController();

  /// Le message "Craqué !" ne doit apparaître qu'une fois que l'animation de
  /// lancer des dés est terminée (résultat visible), pas dès que le craque
  /// est connu côté moteur : sinon le suspense du lancer est gâché.
  static const _bustRevealDelay = Duration(milliseconds: 700);
  Object? _bustKeyBeingRevealed;
  bool _bustRevealed = false;
  Timer? _bustRevealTimer;

  @override
  void initState() {
    super.initState();
    final initialEngine = ref.read(gameProvider);
    final initialTurn = initialEngine?.activeTurn;
    final initialPendingRoll = initialTurn?.pendingRoll;
    _selectedKeep = initialPendingRoll != null ? _defaultKeepCount(initialTurn!, initialPendingRoll) : 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _seedLogFromHistory();
      if (widget.replayMode) {
        _scheduleReplayStep();
      } else {
        _scheduleAiIfNeeded();
        _scheduleAutoAdvanceIfNeeded();
      }
      _scheduleBustRevealIfNeeded(initialEngine);
    });
  }

  /// Programme puis applique le pas suivant du rejeu spectateur (partie
  /// principale), et se reprogramme lui-même jusqu'à épuisement du journal
  /// (l'écran de victoire se déclenche alors normalement via le `ref.listen`
  /// existant dès que `gameOver` devient vrai). Délai = `aiMessageDelay`
  /// (réglages) divisé par [replaySpeedProvider] (x1/x2/x4).
  void _scheduleReplayStep() {
    final notifier = ref.read(gameProvider.notifier);
    final engine = ref.read(gameProvider);
    if (engine == null || engine.gameOver || !notifier.hasNextReplayAction) return;
    final baseDelay = ref.read(settingsProvider).aiMessageDelay;
    final speed = ref.read(replaySpeedProvider);
    final delay = Duration(microseconds: baseDelay.inMicroseconds ~/ speed);
    _pendingTimer?.cancel();
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(gameProvider.notifier).applyNextReplayAction();
      _scheduleReplayStep();
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    _bustRevealTimer?.cancel();
    _logScrollController.dispose();
    super.dispose();
  }

  /// Ajoute une entrée au journal (le plus récent apparaît en premier, voir
  /// [_buildGameLog] — pas d'auto-scroll nécessaire, une nouvelle entrée
  /// apparaît directement en haut, déjà visible).
  void _appendLog(_LogEntry entry) => setState(() => _log.add(entry));

  /// Reconstruit tout l'historique du journal en rejouant le journal
  /// d'actions déjà persisté par [GameNotifier] (même source que le `.run` —
  /// rien n'est dupliqué), au montage de l'écran : couvre aussi bien une
  /// partie qui vient de démarrer (un seul `startTurn` à rejouer) qu'une
  /// partie reprise (tout son historique). Sans effet si la partie n'est pas
  /// persistée (`debugLoadState` en test, ou mode rejeu — ce dernier peuple
  /// son propre journal en direct au fil de la lecture, voir `ref.listen`).
  void _seedLogFromHistory() {
    final notifier = ref.read(gameProvider.notifier);
    final seed = notifier.seed;
    final originalSetup = notifier.originalSetup;
    final actions = notifier.actions;
    if (seed == null || originalSetup == null || actions.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final entries = <_LogEntry>[];
    replayGame(
      originalSetup,
      seed,
      actions,
      onGameAction: (previous, next, action) {
        entries.addAll(_logEntriesForStep(previous, next, l10n: l10n, at: action.at, includeBust: true));
      },
    );
    if (entries.isEmpty) return;
    setState(() => _log.addAll(entries));
  }

  /// Programme la révélation du message "Craqué !" une fois l'animation de
  /// lancer des dés terminée pour ce lancer précis. Cas particulier : un
  /// craque par dépassement de 10000 (déclenché dans [GameEngine.applyKeep]
  /// après une décision de garde déjà appliquée) n'a plus de lancer en
  /// attente à animer — rien à cacher, la révélation est immédiate.
  void _scheduleBustRevealIfNeeded(GameEngine? engine) {
    final turn = engine?.activeTurn;
    if (turn == null || !turn.busted) return;

    // Clé d'identité du craque en cours : le lancer en attente s'il y en a
    // un, sinon l'état de tour lui-même (craque par dépassement de 10000,
    // déclenché dans [GameEngine.applyKeep] après une décision de garde déjà
    // appliquée — pas de lancer à animer, donc rien à cacher).
    final key = turn.pendingRoll ?? turn;
    if (_bustKeyBeingRevealed == key) return;
    _bustKeyBeingRevealed = key;
    _bustRevealed = false;
    _bustRevealTimer?.cancel();

    if (turn.pendingRoll == null) {
      SoundEffects.instance.playBust();
      _appendLog(_LogEntry(DateTime.now(), engine!.currentPlayer.name, AppLocalizations.of(context).bustedTitle));
      setState(() => _bustRevealed = true);
      return;
    }

    _bustRevealTimer = Timer(_bustRevealDelay, () {
      if (!mounted) return;
      SoundEffects.instance.playBust();
      _appendLog(_LogEntry(DateTime.now(), engine!.currentPlayer.name, AppLocalizations.of(context).bustedTitle));
      setState(() => _bustRevealed = true);
    });
  }

  /// Programme [action] pour s'exécuter seule après [delay] (réglable dans
  /// les préférences ; 0 = quasi immédiat), sauf si l'utilisateur clique
  /// entre-temps n'importe où sur l'écran (voir [_skipPendingAction]),
  /// auquel cas elle s'exécute immédiatement.
  void _scheduleAutoAction(VoidCallback action, Duration delay) {
    _pendingTimer?.cancel();
    _pendingAction = action;
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      _pendingAction = null;
      action();
    });
  }

  void _cancelAutoAction() {
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
  }

  /// Exécute immédiatement l'action automatique en attente, si il y en a
  /// une : appelé quand l'utilisateur clique sur l'écran pour sauter le
  /// délai de temporisation.
  void _skipPendingAction() {
    final action = _pendingAction;
    if (action == null) return;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
    action();
  }

  /// Programme (ou annule) l'auto-validation d'[action] selon le mode auto
  /// du joueur [playerIndex] et le délai [delay] réglé dans les préférences :
  /// un bouton explicite reste toujours affiché et cliquable (voir les
  /// méthodes `_build*View`), mais ne se déclenche seul que si les deux
  /// conditions sont réunies (délai > 0 requis, sinon "désactivé").
  void _scheduleIfAuto(int playerIndex, VoidCallback action, Duration delay) {
    final notifier = ref.read(gameProvider.notifier);
    if (notifier.isAutoPlayer(playerIndex) && delay > Duration.zero) {
      _scheduleAutoAction(action, delay);
    } else {
      _cancelAutoAction();
    }
  }

  void _scheduleAiIfNeeded() {
    final engine = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (engine == null || engine.gameOver) return;
    if (!notifier.isAiPlayer(engine.currentPlayerIndex)) return;
    _scheduleIfAuto(
      engine.currentPlayerIndex,
      () => ref.read(gameProvider.notifier).playAiTurnStep(),
      ref.read(settingsProvider).aiMessageDelay,
    );
  }

  /// Programme l'auto-validation du tour d'un joueur humain (en mode auto)
  /// quand il n'y a aucune décision réelle à prendre : pas de choix possible
  /// sur les 5 à garder (on garde tout d'office), ou score insuffisant/50
  /// interdit/dés chauds obligeant de toute façon à relancer. Un bouton
  /// explicite est affiché dans tous les cas par les méthodes `_build*View`.
  void _scheduleAutoAdvanceIfNeeded() {
    final engine = ref.read(gameProvider);
    final notifier = ref.read(gameProvider.notifier);
    if (engine == null || engine.gameOver) return;
    if (notifier.isAiPlayer(engine.currentPlayerIndex)) return; // géré par _scheduleAiIfNeeded
    final turn = engine.activeTurn;
    if (turn == null || turn.busted) {
      _cancelAutoAction();
      return;
    }

    if (turn.pendingRoll != null) {
      final analysis = turn.pendingRoll!;
      if (_hasRealChoice(analysis)) {
        _cancelAutoAction();
        return;
      }
      _scheduleIfAuto(engine.currentPlayerIndex, () {
        if (ref.read(gameProvider)?.activeTurn?.pendingRoll != analysis) return;
        ref.read(gameProvider.notifier).applyKeep(declineFivesCount: 0);
      }, ref.read(settingsProvider).autoActionDelay);
      return;
    }

    final attempt = tryBank(
      turn,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
    );
    if (attempt.success) {
      _cancelAutoAction();
      return;
    }
    _scheduleIfAuto(engine.currentPlayerIndex, () {
      final currentTurn = ref.read(gameProvider)?.activeTurn;
      if (currentTurn != turn) return;
      ref.read(gameProvider.notifier).roll();
    }, ref.read(settingsProvider).autoActionDelay);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GameEngine?>(gameProvider, (previous, next) {
      if (next == null) return;
      if (next.gameOver) {
        SoundEffects.instance.playVictory();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GameOverScreen(players: next.players, winnerIndex: next.winnerIndex!),
        ));
        return;
      }
      if (!widget.replayMode &&
          previous != null &&
          next.currentPlayerIndex != previous.currentPlayerIndex &&
          ref.read(gameProvider.notifier).shouldShowPassDevice(next.currentPlayerIndex)) {
        Navigator.of(context)
            .push(MaterialPageRoute(
              builder: (_) => PassDeviceScreen(nextPlayerName: next.currentPlayer.name),
            ))
            .then((_) => _scheduleAiIfNeeded());
      }
      for (final entry
          in _logEntriesForStep(previous, next, l10n: AppLocalizations.of(context), at: DateTime.now(), includeBust: false)) {
        _appendLog(entry);
      }
      final newPendingRoll = next.activeTurn?.pendingRoll;
      if (previous?.activeTurn?.pendingRoll != newPendingRoll) {
        if (newPendingRoll != null) SoundEffects.instance.playDiceRoll();
        // Par défaut, on tend vers le score optimal (voir _defaultKeepCount).
        _selectedKeep = newPendingRoll != null ? _defaultKeepCount(next.activeTurn!, newPendingRoll) : 0;
      }
      // En mode rejeu, _scheduleReplayStep s'auto-reprogramme lui-même
      // (voir initState) : pas besoin de le redéclencher ici, et surtout pas
      // la logique de décision IA/auto normale, qui ne s'applique pas.
      if (!widget.replayMode) {
        _scheduleAiIfNeeded();
        _scheduleAutoAdvanceIfNeeded();
      }
      _scheduleBustRevealIfNeeded(next);
    });

    final engine = ref.watch(gameProvider);
    if (engine == null || engine.gameOver) {
      // Partie terminée : l'écran de fin de partie est poussé par le
      // ref.listen ci-dessus, activeTurn est déjà nettoyé côté moteur.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final notifier = ref.read(gameProvider.notifier);
    final isAiTurn = notifier.isAiPlayer(engine.currentPlayerIndex);

    if (engine.activeTurn == null) {
      // Dés hérités d'un tour précédent : le joueur doit choisir de les
      // garder ou de repartir avec une main pleine, avant que le tour ne
      // démarre réellement. Écran distinct, pas encore de TurnState à
      // afficher dans les zones "Lancé"/"Main courante".
      return Scaffold(
        appBar: AppBar(title: const AppTitle(), actions: _scoreGridAction(engine.players)),
        body: AbsorbPointer(
          absorbing: widget.replayMode,
          child: GestureDetector(
            onTap: _skipPendingAction,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ScoreSheet(
                      players: engine.players,
                      currentPlayerIndex: engine.currentPlayerIndex,
                      onTapPlayer: _openPlayerGrid,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: isAiTurn ? _buildAiHandChoiceView(engine) : _buildHandChoiceView(engine),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final turn = engine.activeTurn!;
    final l10n = AppLocalizations.of(context);

    // Score "live" : score du tour déjà banqué + aperçu de la sélection de 5
    // en cours si un choix humain est en attente (même valeur qu'avant cette
    // refonte, juste renommée pour la ligne de score colorée ci-dessous).
    final liveScore = !isAiTurn && turn.pendingRoll != null
        ? turn.bankedScore + _previewPoints(turn.pendingRoll!, _selectedKeep)
        : turn.bankedScore;
    final minimum = engine.minimumForCurrentPlayer;
    final belowMinimum = liveScore < minimum;
    final scoreColor = belowMinimum ? Colors.redAccent : (liveScore % 100 == 50 ? Colors.orange : Colors.lightGreenAccent);
    final minimumColor = belowMinimum ? Colors.redAccent : Colors.lightGreenAccent;
    // Aperçu (ChoiceChip) seulement pertinent pour un lancer humain en
    // attente de décision ; sinon (IA, craque, idle) les dés du lancer, s'il
    // y en a un à afficher, sont montrés "tels quels" (rien n'est encore
    // décidé côté joueur).
    final rollZoneSelectedKeep = (!turn.busted && !isAiTurn && turn.pendingRoll != null) ? _selectedKeep : 0;

    return Scaffold(
      appBar: AppBar(title: const AppTitle(), actions: _scoreGridAction(engine.players)),
      body: GestureDetector(
        onTap: _skipPendingAction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Le contenu (liste des joueurs + score + 2 zones bordurées +
            // boutons + journal) peut dépasser la hauteur disponible sur un
            // petit écran (ou un choix de 5 avec beaucoup de ChoiceChip) :
            // tout défile ensemble, le journal gardant une hauteur fixe
            // plutôt que de se répartir l'espace restant, pour qu'il reste
            // toujours visible sans avoir à tout faire défiler.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ScoreSheet(
                    players: engine.players,
                    currentPlayerIndex: engine.currentPlayerIndex,
                    activeTurn: turn,
                    onTapPlayer: _openPlayerGrid,
                  ),
                  const SizedBox(height: 12),
                  if (engine.isInFinalRound)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(l10n.finalRoundBanner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    ),
                  _buildRollZone(turn, rollZoneSelectedKeep),
                  const SizedBox(height: 12),
                  _buildHandZone(turn, liveScore: liveScore, minimum: minimum, scoreColor: scoreColor, minimumColor: minimumColor),
                  const SizedBox(height: 12),
                  Center(
                    child: turn.busted
                        ? _buildBustedView(turn)
                        : (isAiTurn
                            ? _buildAiTurnView(engine, turn)
                            : (turn.pendingRoll != null
                                ? _buildPendingRollView(engine, turn)
                                : _buildIdleView(engine, turn))),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(height: 240, child: _buildGameLog()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _scoreGridAction(List<Player> players) {
    // En mode rejeu, seul le retour compte (flèche standard de l'AppBar) :
    // pas d'icône grille de score ni "quitter", juste le sélecteur de
    // vitesse x1/x2/x4.
    if (widget.replayMode) return const [ReplaySpeedControl()];

    final l10n = AppLocalizations.of(context);
    return [
      IconButton(
        icon: const Icon(Icons.grid_on),
        tooltip: l10n.scoreGridLabel,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ScoreGridScreen(players: players)),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.exit_to_app),
        tooltip: l10n.leaveGameTooltip,
        // La partie est déjà sauvegardée en continu après chaque transition
        // (voir GameNotifier) : quitter ne nécessite aucune action explicite
        // de sauvegarde, juste revenir à l'écran d'accueil.
        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    ];
  }

  /// Ouvre la grille de score filtrée sur un seul joueur (clic sur sa ligne
  /// dans le [ScoreSheet]) : son nom complet sert alors de libellé de
  /// colonne plutôt que des initiales.
  void _openPlayerGrid(Player player) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ScoreGridScreen(players: [player])));
  }

  Widget _buildHandChoiceView(GameEngine engine) {
    final l10n = AppLocalizations.of(context);
    final canContinue = !engine.inheritedHandExceedsWinningScore;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.inheritedHandMessage(engine.currentPlayer.name, engine.nextTurnDice),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(l10n.currentScoreLabel(engine.inheritedScore),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _fittedDiceRow(
          engine.inheritedKeptDice.length,
          (i, size) => DieWidget(
            value: engine.inheritedKeptDice[i].value,
            state: engine.inheritedKeptDice[i].isExtended ? DieVisualState.extended : DieVisualState.kept,
            bodyColor: _diceColor(i),
            size: size,
          ),
        ),
        const SizedBox(height: 24),
        if (canContinue)
          FilledButton(
            onPressed: () => ref.read(gameProvider.notifier).startTurn(useFullHand: false),
            child: Text(l10n.continueWithDiceButton(engine.nextTurnDice)),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.inheritedHandExceedsWinning,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => ref.read(gameProvider.notifier).startTurn(useFullHand: true),
          child: Text(l10n.restartWithFreshDiceButton),
        ),
      ],
    );
  }

  /// Choix de main hérité pour l'IA : un unique bouton reflétant la décision
  /// qu'elle prendrait (voir [GameNotifier.previewAiAcceptInheritedHand]),
  /// qui déclenche cette même décision (via [GameNotifier.playAiTurnStep]).
  Widget _buildAiHandChoiceView(GameEngine engine) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gameProvider.notifier);
    final accepts = notifier.previewAiAcceptInheritedHand();
    final label = accepts ? l10n.aiContinueWithDiceButton(engine.nextTurnDice) : l10n.aiRestartWithFreshDiceLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.inheritedHandMessage(engine.currentPlayer.name, engine.nextTurnDice),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Text(l10n.currentScoreLabel(engine.inheritedScore),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _fittedDiceRow(
          engine.inheritedKeptDice.length,
          (i, size) => DieWidget(
            value: engine.inheritedKeptDice[i].value,
            state: engine.inheritedKeptDice[i].isExtended ? DieVisualState.extended : DieVisualState.kept,
            bodyColor: _diceColor(i),
            size: size,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => ref.read(gameProvider.notifier).playAiTurnStep(),
          child: Text(label),
        ),
      ],
    );
  }

  /// Hauteur fixe de la zone "Piste" (dés uniquement désormais) : une seule
  /// rangée de dés à leur taille par défaut, quel que soit l'état (lancer en
  /// attente ou non) — évite que la zone change de hauteur selon le contenu.
  static const double _rollZoneHeight = DieWidget.defaultSize + 16;

  /// Zone bordurée "Piste" : uniquement les dés du lancer en attente de
  /// décision (ou rien, zone vide, s'il n'y en a aucun) — son score va dans
  /// le libellé lui-même, entre parenthèses. `selectedKeep` ne pèse que sur
  /// l'aperçu visuel (voir `_classifyDiceForDisplay`) : 0 pour l'IA/un
  /// craque (rien n'est encore "décidé" à afficher), la sélection réelle du
  /// joueur sinon.
  Widget _buildRollZone(TurnState turn, int selectedKeep) {
    final l10n = AppLocalizations.of(context);
    final analysis = turn.pendingRoll;
    final label = analysis != null
        ? l10n.currentRollZoneLabelWithScore(_previewPoints(analysis, selectedKeep))
        : l10n.currentRollZoneLabel;
    return BorderedSection(
      label: label,
      fillAvailableSpace: false,
      child: SizedBox(
        height: _rollZoneHeight,
        child: Center(child: analysis != null ? _diceRow(analysis, selectedKeep) : const SizedBox.shrink()),
      ),
    );
  }

  /// Zone bordurée "Main courante" : les dés gardés ce tour, avec le score du
  /// tour (et le minimum requis) dans le libellé, coloré comme avant cette
  /// refonte (juste déplacé depuis sa propre ligne).
  Widget _buildHandZone(
    TurnState turn, {
    required int liveScore,
    required int minimum,
    required Color scoreColor,
    required Color minimumColor,
  }) {
    final l10n = AppLocalizations.of(context);
    return BorderedSection(
      label: l10n.currentHandZoneLabel,
      fillAvailableSpace: false,
      labelSuffix: [
        const TextSpan(text: ' '),
        TextSpan(text: '$liveScore', style: TextStyle(color: scoreColor)),
        TextSpan(text: ' (>$minimum)', style: TextStyle(color: minimumColor)),
      ],
      child: turn.keptDiceThisTurn.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('—', style: TextStyle(color: Colors.grey.shade400)),
            )
          : _keptDiceRow(turn),
    );
  }

  /// Journal de partie : lecture seule, horodaté, du plus récent (en haut) au
  /// plus ancien — pas besoin de gérer le défilement, une nouvelle entrée
  /// apparaît directement en haut, déjà dans la zone visible.
  Widget _buildGameLog() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: _log.isEmpty
          ? Center(child: Text('—', style: TextStyle(color: Colors.grey.shade400)))
          : Scrollbar(
              controller: _logScrollController,
              thumbVisibility: true,
              thickness: 3,
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _log.length,
                itemBuilder: (context, i) {
                  final entry = _log[_log.length - 1 - i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_formatLogDate(entry.timestamp)} - ${_formatLogTime(entry.timestamp)} - ',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: PlayerAvatarWidget(name: entry.playerName, size: 16),
                        ),
                        Expanded(
                          child: Text(' : ${entry.text}', style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  /// Tour de l'IA en cours : un unique bouton explicite reflétant l'action
  /// qu'elle va effectuer, qui déclenche cette même action (les deux
  /// s'appuient sur la même logique de décision, voir [GameNotifier]).
  /// Le craque est géré séparément par [_buildBustedView] (appelé avant
  /// celle-ci par l'appelant, IA ou humain confondus).
  Widget _buildAiTurnView(GameEngine engine, TurnState turn) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(gameProvider.notifier);
    void action() => ref.read(gameProvider.notifier).playAiTurnStep();

    if (turn.pendingRoll != null) {
      return FilledButton(onPressed: action, child: Text(l10n.keepDiceButton));
    }

    final String label;
    if (turn.mustContinue) {
      label = l10n.reRollFullHandButton;
    } else if (tryBank(
              turn,
              minimumRequired: engine.minimumForCurrentPlayer,
              currentTotal: engine.currentPlayer.totalScore,
            ).success &&
        !notifier.previewAiContinue(turn)) {
      label = l10n.stopButton;
    } else {
      label = l10n.rollDiceButton;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.diceToRollLabel(turn.diceToRoll), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton(onPressed: action, child: Text(label)),
      ],
    );
  }

  Widget _buildBustedView(TurnState turn) {
    // Le résultat n'est révélé qu'une fois l'animation de lancer des dés
    // terminée (cf. _scheduleBustRevealIfNeeded) : le suspense du lancer ne
    // doit pas être gâché par un message qui s'affiche trop tôt.
    final l10n = AppLocalizations.of(context);
    final key = turn.pendingRoll ?? turn;
    final revealed = _bustRevealed && _bustKeyBeingRevealed == key;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!revealed)
          const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
        else ...[
          // Pas de titre "Craqué !" ici : il apparaît déjà dans le journal de
          // partie (voir _scheduleBustRevealIfNeeded), pas besoin de le
          // répéter en double au-dessus du bouton.
          if (turn.pendingRoll == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.bustExceedsTarget, style: const TextStyle(color: Colors.orange)),
            ),
          FilledButton(
            onPressed: () => ref.read(gameProvider.notifier).endBustedTurn(),
            child: Text(l10n.continueButton),
          ),
        ],
      ],
    );
  }

  Widget _buildPendingRollView(GameEngine engine, TurnState turn) {
    final l10n = AppLocalizations.of(context);
    final analysis = turn.pendingRoll!;
    final fives = analysis.declinableFives;
    final canChoose = _hasRealChoice(analysis);
    final minKeep = analysis.mandatoryGroups.isEmpty ? 1 : 0;
    final declineCount = (fives?.diceCount ?? 0) - _selectedKeep;

    // Simule la décision de garde en cours pour savoir si s'arrêter serait
    // possible juste après : évite un écran intermédiaire "Valider" séparé
    // de la décision de continuer/s'arrêter.
    final hypothetical = applyKeepDecision(turn, declineFivesCount: declineCount);
    final hypotheticalBank = tryBank(
      hypothetical,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canChoose) ...[
          Text(l10n.howManyFivesToKeep),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var i = minKeep; i <= fives!.diceCount; i++)
                ChoiceChip(
                  label: Text('$i'),
                  selected: _selectedKeep == i,
                  onSelected: (_) => setState(() => _selectedKeep = i),
                ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // Pas de bouton "Garder les dés" générique : s'il n'y a aucun 5 à
        // éliminer (pas de vrai choix), la décision de garde forcée est
        // appliquée directement en même temps que l'action suivante — comme
        // quand un choix existe (voir CLAUDE.md, pas d'écran "Valider"
        // intermédiaire).
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              onPressed: () {
                final notifier = ref.read(gameProvider.notifier);
                notifier.applyKeep(declineFivesCount: declineCount);
                notifier.roll();
              },
              child: Text(l10n.rollDiceButton),
            ),
            if (hypotheticalBank.success) ...[
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () {
                  final notifier = ref.read(gameProvider.notifier);
                  notifier.applyKeep(declineFivesCount: declineCount);
                  notifier.bank();
                },
                child: Text(l10n.stopButton),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIdleView(GameEngine engine, TurnState turn) {
    final l10n = AppLocalizations.of(context);
    final attempt = tryBank(
      turn,
      minimumRequired: engine.minimumForCurrentPlayer,
      currentTotal: engine.currentPlayer.totalScore,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.diceToRollLabel(turn.diceToRoll), style: Theme.of(context).textTheme.titleMedium),
        if (turn.mustContinue)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.fullHandMustReroll,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          )
        else if (!attempt.success)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_failureMessage(l10n, attempt), style: TextStyle(color: Colors.grey.shade400)),
          ),
        const SizedBox(height: 24),
        if (attempt.success)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: () => ref.read(gameProvider.notifier).roll(),
                child: Text(l10n.rollDiceButton),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => ref.read(gameProvider.notifier).bank(),
                child: Text(l10n.stopButton),
              ),
            ],
          )
        else
          FilledButton(
            onPressed: () => ref.read(gameProvider.notifier).roll(),
            child: Text(turn.mustContinue ? l10n.reRollFullHandButton : l10n.rollDiceButton),
          ),
      ],
    );
  }

  String _failureMessage(AppLocalizations l10n, BankAttempt attempt) {
    switch (attempt.reason) {
      case BankFailureReason.belowMinimum:
        return l10n.failureBelowMinimum;
      case BankFailureReason.endsIn50:
        return l10n.failureEndsIn50;
      case BankFailureReason.mustContinueHotDice:
        return l10n.failureMustContinueHotDice;
      case BankFailureReason.notRolledYet:
        return l10n.failureNotRolledYet;
      case BankFailureReason.wouldMakeWinningImpossible:
        return l10n.failureWouldMakeWinningImpossible;
      case null:
        return '';
    }
  }

  Color? _diceColor(int index) => diceBodyColorFor(ref.watch(settingsProvider).diceColorMode, index);

  Widget _diceRow(RollAnalysis analysis, int selectedKeep) {
    final states = _classifyDiceForDisplay(analysis, selectedKeep);
    return _fittedDiceRow(
      analysis.faces.length,
      (i, size) => DieWidget(
        value: analysis.faces[i],
        state: states[i],
        rollToken: analysis,
        bodyColor: _diceColor(i),
        size: size,
      ),
    );
  }

  Widget _keptDiceRow(TurnState turn) {
    final kept = turn.keptDiceThisTurn;
    return _fittedDiceRow(
      kept.length,
      (i, size) => DieWidget(
        value: kept[i].value,
        state: kept[i].isExtended ? DieVisualState.extended : DieVisualState.kept,
        bodyColor: _diceColor(i),
        size: size,
      ),
    );
  }
}

/// Construit une rangée d'exactement [count] dés qui tient toujours sur une
/// seule ligne : la taille de chaque dé est réduite (jamais en dessous de
/// 40px, jamais au-dessus de la taille par défaut) pour que
/// `count * (taille + marge)` ne dépasse jamais la largeur disponible — donc
/// adaptée à la fois à la largeur de l'écran et à son orientation.
Widget _fittedDiceRow(int count, Widget Function(int index, double size) builder) {
  if (count == 0) return const SizedBox.shrink();
  const dieMargin = 8.0; // EdgeInsets.all(4) appliqué de chaque côté par DieWidget
  const minSize = 40.0;
  return LayoutBuilder(
    builder: (context, constraints) {
      final available = constraints.maxWidth.isFinite ? constraints.maxWidth : DieWidget.defaultSize * count;
      final size = ((available / count) - dieMargin).clamp(minSize, DieWidget.defaultSize);
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [for (var i = 0; i < count; i++) builder(i, size)],
      );
    },
  );
}
