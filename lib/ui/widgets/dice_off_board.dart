import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/dice_off.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_providers.dart';
import '../dice_colors.dart';
import 'die_widget.dart';

/// Ce que montre le tirage au sort : un dé par joueur, puis l'annonce de qui
/// commence. L'ordre de jeu, lui, n'est plus annoncé : la liste des joueurs de
/// l'écran de jeu le montre de toute façon, en tournant autour de celui dont
/// c'est le tour. Partagé par le tirage local (`DiceOffScreen`) et par celui
/// d'une partie en ligne, où le serveur a déjà tout tranché et l'écran ne fait
/// que le raconter.
///
/// [shownName] donne le nom affiché d'un siège (surnom compris).
/// [startButton], quand fourni, ajoute sous le résultat le bouton qui lance la
/// partie : son libellé, et son action — nulle, le bouton est affiché inerte
/// (un joueur en ligne qui attend que celui qui commence lance la partie).
class DiceOffBoard extends ConsumerWidget {
  final DiceOffState state;
  final String Function(int seat) shownName;
  final ({String label, VoidCallback? onPressed})? startButton;

  const DiceOffBoard({super.key, required this.state, required this.shownName, this.startButton});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.diceOffInstructions, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        _diceRow(context, ref),
        const SizedBox(height: 24),
        if (state.isResolved) _result(context, l10n) else _status(context, l10n),
      ],
    );
  }

  Widget _status(BuildContext context, AppLocalizations l10n) {
    // Avant le premier round, rien à dire : les dés partent d'eux-mêmes.
    if (state.roundHistory.isEmpty) return const SizedBox.shrink();
    return Text(
      l10n.diceOffTieBreak(state.activeIndices.map(shownName).join(', ')),
      style: TextStyle(color: TableColors.of(context).warning, fontWeight: FontWeight.bold),
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
        if (startButton case final button?) ...[
          const SizedBox(height: 32),
          FilledButton(onPressed: button.onPressed, child: Text(button.label)),
        ],
      ],
    );
  }

  /// Un dé par joueur, dans l'ordre de la liste, montrant son dernier lancer.
  /// Seuls les dés du round qui vient d'être joué s'animent ; ceux des joueurs
  /// déjà départagés restent posés, estompés.
  Widget _diceRow(BuildContext context, WidgetRef ref) {
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
          _seatDie(context, seat, lastRoll[seat], diceBodyColorFor(colorMode, seat)),
      ],
    );
  }

  Widget _seatDie(BuildContext context, int seat, ({int value, int round})? roll, Color? bodyColor) {
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
          Text(shownName(seat), style: TextStyle(fontSize: 12, color: TableColors.of(context).muted)),
          const SizedBox(height: 4),
          if (roll == null)
            SizedBox.square(
              dimension: DieWidget.defaultSize,
              child: Center(child: Icon(Icons.casino_outlined, color: TableColors.of(context).muted)),
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
