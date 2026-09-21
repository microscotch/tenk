import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/replay_pause_provider.dart';
import '../../state/replay_progress_provider.dart';
import 'replay_speed_control.dart';

/// Les commandes du rejeu spectateur, en bas de l'écran de jeu : un curseur
/// pour aller droit à un tour, la pause / lecture, et la vitesse (x1/x2/x4).
///
/// [onSeek] reçoit le tour choisi ; le curseur suit la progression du rejeu
/// (voir [replayProgressProvider]) tant qu'on ne le tient pas.
class ReplayControls extends ConsumerStatefulWidget {
  final ValueChanged<int> onSeek;

  const ReplayControls({super.key, required this.onSeek});

  /// Hauteur de l'ensemble, que l'écran de jeu retire au journal pour la lui
  /// laisser (voir `GameScreen`).
  static const height = 96.0;

  @override
  ConsumerState<ReplayControls> createState() => _ReplayControlsState();
}

class _ReplayControlsState extends ConsumerState<ReplayControls> {
  /// Le tour sous le doigt pendant qu'on fait glisser le curseur ; nul sinon,
  /// le curseur reprend alors la progression du rejeu.
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final progress = ref.watch(replayProgressProvider);
    final paused = ref.watch(replayPausedProvider);
    final scheme = Theme.of(context).colorScheme;
    // Du premier au dernier tour : le curseur désigne le tour à l'écran, il n'y
    // a donc rien à gauche du premier. Sans au moins deux tours, rien à choisir.
    final canSeek = progress.count >= 2;
    final max = canSeek ? progress.count : 2;
    final value = (_dragging ?? progress.turn.toDouble()).clamp(1, max.toDouble());

    return SizedBox(
      height: ReplayControls.height,
      child: Column(
        children: [
          Row(
            children: [
              IconButton.filled(
                tooltip: paused ? l10n.replayPlay : l10n.replayPause,
                onPressed: () => ref.read(replayPausedProvider.notifier).toggle(),
                icon: Icon(paused ? Icons.play_arrow : Icons.pause),
              ),
              Expanded(
                child: Slider(
                  min: 1,
                  max: max.toDouble(),
                  divisions: max - 1,
                  value: value.toDouble(),
                  onChanged: canSeek ? (v) => setState(() => _dragging = v) : null,
                  onChangeEnd: (v) {
                    setState(() => _dragging = null);
                    widget.onSeek(v.round());
                  },
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  l10n.replayTurnOf(value.round(), progress.count),
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurface),
                ),
              ),
            ],
          ),
          const ReplaySpeedControl(),
        ],
      ),
    );
  }
}
