import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/replay_speed_provider.dart';

/// Sélecteur x1/x2/x4 affiché dans l'`AppBar` des écrans en mode rejeu
/// spectateur : divise le délai entre deux actions (voir
/// [replaySpeedProvider]).
class ReplaySpeedControl extends ConsumerWidget {
  const ReplaySpeedControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(replaySpeedProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('x1')),
          ButtonSegment(value: 2, label: Text('x2')),
          ButtonSegment(value: 4, label: Text('x4')),
        ],
        selected: {speed},
        showSelectedIcon: false,
        onSelectionChanged: (s) => ref.read(replaySpeedProvider.notifier).set(s.first),
      ),
    );
  }
}
