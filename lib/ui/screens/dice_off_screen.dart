import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/dice_off_providers.dart';
import '../../state/game_providers.dart';
import '../../state/player_providers.dart';
import '../../state/player_store.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import '../sound_effects.dart';
import '../widgets/die_widget.dart';
import 'game_screen.dart';

/// Détermine qui commence la partie et dans quel sens elle tourne : tous les
/// joueurs lancent leur dé en même temps, le plus faible commence, et les
/// ex-aequo au plus bas relancent seuls jusqu'à se départager. Tout se joue
/// sans intervention ; un tap sur l'écran abrège l'attente avant une relance.
class DiceOffScreen extends ConsumerStatefulWidget {
  const DiceOffScreen({super.key});

  /// Pause avant le premier lancer, le temps que l'écran s'installe.
  static const firstRollDelay = Duration(milliseconds: 500);

  /// Pause entre deux rounds : l'animation du dé, puis de quoi lire qui est à
  /// égalité avant que ses dés repartent.
  static const tieRerollDelay = Duration(milliseconds: 1800);

  @override
  ConsumerState<DiceOffScreen> createState() => _DiceOffScreenState();
}

class _DiceOffScreenState extends ConsumerState<DiceOffScreen> {
  Timer? _pendingTimer;
  VoidCallback? _pendingAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(diceOffProvider);
      if (state == null) return;
      if (state.isResolved) {
        _scheduleAutoStartIfNeeded();
      } else {
        _schedule(_rollRound, DiceOffScreen.firstRollDelay);
      }
    });
  }

  @override
  void dispose() {
    _pendingTimer?.cancel();
    super.dispose();
  }

  void _schedule(VoidCallback action, Duration delay) {
    _pendingTimer?.cancel();
    _pendingAction = action;
    _pendingTimer = Timer(delay, () {
      if (!mounted) return;
      _pendingAction = null;
      action();
    });
  }

  void _skipPendingAction() {
    final action = _pendingAction;
    if (action == null) return;
    _pendingTimer?.cancel();
    _pendingTimer = null;
    _pendingAction = null;
    action();
  }

  void _rollRound() {
    SoundEffects.instance.playDiceRoll();
    ref.read(diceOffProvider.notifier).rollRound();
    if (ref.read(diceOffProvider)!.isResolved) {
      _scheduleAutoStartIfNeeded();
    } else {
      _schedule(_rollRound, DiceOffScreen.tieRerollDelay);
    }
  }

  /// Quand tous les joueurs sont des IA en mode auto, personne n'est là pour
  /// cliquer sur "Commencer la partie" une fois l'ordre déterminé : la
  /// partie démarre donc seule, après le délai IA réglé dans les préférences.
  void _scheduleAutoStartIfNeeded() {
    final notifier = ref.read(diceOffProvider.notifier);
    if (notifier.humanPlayerCount > 0 || !notifier.allPlayersAreAuto) return;
    final delay = ref.read(settingsProvider).aiMessageDelay;
    if (delay <= Duration.zero) return;
    _schedule(_startGame, delay);
  }

  /// Le nom sous lequel le joueur du siège [seat] est appelé : son surnom quand
  /// sa fiche en porte un (voir `displayNamesFor`). Le tirage au sort se joue
  /// sur la config d'origine, avant que l'ordre de jeu soit fixé.
  String _shownName(int seat) {
    final notifier = ref.read(diceOffProvider.notifier);
    final names = displayNamesFor(notifier.setup, ref.read(playersProvider).value);
    return displayNameOf(names, notifier.nameOf(seat));
  }

  void _startGame() {
    if (!mounted) return;
    _pendingTimer?.cancel();
    _pendingAction = null;
    final diceOffNotifier = ref.read(diceOffProvider.notifier);
    final ordered = diceOffNotifier.buildOrderedSetup();
    ref.read(gameProvider.notifier).startGame(ordered, handoff: diceOffNotifier.handoff());
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(diceOffProvider);
    if (state == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.diceOffTitle)),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skipPendingAction,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.diceOffInstructions, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    _diceRow(state),
                    const SizedBox(height: 24),
                    if (state.isResolved) _result(l10n, state) else _status(l10n, state),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _status(AppLocalizations l10n, DiceOffState state) {
    // Avant le premier round, rien à dire : les dés partent d'eux-mêmes.
    if (state.roundHistory.isEmpty) return const SizedBox.shrink();
    return Text(
      l10n.diceOffTieBreak(state.activeIndices.map(_shownName).join(', ')),
      style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _result(AppLocalizations l10n, DiceOffState state) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.diceOffWinnerAnnouncement(_shownName(state.winnerIndex!)),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(l10n.diceOffPlayOrderLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          state.playOrder.map(_shownName).join('  →  '),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (state.reversesOrder) ...[
          const SizedBox(height: 8),
          Text(
            l10n.diceOffReversedNote,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 32),
        FilledButton(onPressed: _startGame, child: Text(l10n.startGameButton)),
      ],
    );
  }

  /// Un dé par joueur, dans l'ordre de la liste, montrant son dernier lancer.
  /// Seuls les dés du round qui vient d'être joué s'animent ; ceux des joueurs
  /// déjà départagés restent posés, estompés.
  Widget _diceRow(DiceOffState state) {
    final colorMode = ref.watch(settingsProvider).diceColorMode;
    final lastRoll = <int, ({int value, int round})>{};
    for (var r = 0; r < state.roundHistory.length; r++) {
      state.roundHistory[r].forEach((seat, value) => lastRoll[seat] = (value: value, round: r));
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        for (var seat = 0; seat < state.playerCount; seat++)
          _seatDie(state, seat, lastRoll[seat], diceBodyColorFor(colorMode, seat)),
      ],
    );
  }

  Widget _seatDie(DiceOffState state, int seat, ({int value, int round})? roll, Color? bodyColor) {
    final stillIn = state.isResolved ? seat == state.winnerIndex : state.activeIndices.contains(seat);
    final visualState = !stillIn
        ? DieVisualState.junk
        : state.isResolved
            ? DieVisualState.kept
            : DieVisualState.declined;

    return Opacity(
      opacity: roll != null && !stillIn ? 0.45 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_shownName(seat), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          if (roll == null)
            const SizedBox.square(
              dimension: DieWidget.defaultSize,
              child: Center(child: Icon(Icons.casino_outlined, color: Colors.grey)),
            )
          else
            DieWidget(
              value: roll.value,
              state: visualState,
              rollToken: '${roll.round}-$seat',
              bodyColor: bodyColor,
            ),
        ],
      ),
    );
  }
}
