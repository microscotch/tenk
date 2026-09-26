import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import 'die_widget.dart';

/// Ce que montre le tirage au sort : un dé par joueur, puis l'annonce de qui
/// commence et dans quel ordre on joue. Partagé par le tirage local
/// (`DiceOffScreen`) et par celui d'une partie en ligne, où le serveur a déjà
/// tout tranché et l'écran ne fait que le raconter.
///
/// [shownName] donne le nom affiché d'un siège (surnom compris). [onStart],
/// quand fourni, ajoute le bouton qui lance la partie une fois le résultat
/// connu ; [startLabel] en est le libellé.
class DiceOffBoard extends ConsumerWidget {
  final DiceOffState state;
  final String Function(int seat) shownName;
  final VoidCallback? onStart;
  final String? startLabel;

  const DiceOffBoard({super.key, required this.state, required this.shownName, this.onStart, this.startLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.diceOffInstructions, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _diceRow(ref),
        const SizedBox(height: 24),
        if (state.isResolved) _result(context, l10n) else _status(l10n),
      ],
    );
  }

  Widget _status(AppLocalizations l10n) {
    // Avant le premier round, rien à dire : les dés partent d'eux-mêmes.
    if (state.roundHistory.isEmpty) return const SizedBox.shrink();
    return Text(
      l10n.diceOffTieBreak(state.activeIndices.map(shownName).join(', ')),
      style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _result(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.diceOffWinnerAnnouncement(shownName(state.winnerIndex!)),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(l10n.diceOffPlayOrderLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(
          state.playOrder.map(shownName).join('  →  '),
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
        if (onStart != null) ...[
          const SizedBox(height: 32),
          FilledButton(onPressed: onStart, child: Text(startLabel ?? l10n.startGameButton)),
        ],
      ],
    );
  }

  /// Un dé par joueur, dans l'ordre de la liste, montrant son dernier lancer.
  /// Seuls les dés du round qui vient d'être joué s'animent ; ceux des joueurs
  /// déjà départagés restent posés, estompés.
  Widget _diceRow(WidgetRef ref) {
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
          _seatDie(seat, lastRoll[seat], diceBodyColorFor(colorMode, seat)),
      ],
    );
  }

  Widget _seatDie(int seat, ({int value, int round})? roll, Color? bodyColor) {
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
          Text(shownName(seat), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
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
