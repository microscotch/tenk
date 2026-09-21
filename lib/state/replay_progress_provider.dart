import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_providers.dart';

/// Suit le moteur du rejeu : chaque action appliquée peut faire avancer le
/// tour, donc chaque changement d'état relit la progression.
final replayProgressProvider = Provider<ReplayProgress>((ref) {
  ref.watch(gameProvider);
  return ref.read(gameProvider.notifier).replayProgress;
});
