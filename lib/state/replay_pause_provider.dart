import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Le rejeu spectateur est-il en pause ? Partagé entre les commandes du bas de
/// l'écran de rejeu (voir `ReplayControls`) et l'écran de jeu, qui suspend
/// alors son avancée automatique. Un rejeu démarre toujours en lecture.
final replayPausedProvider = NotifierProvider<ReplayPausedNotifier, bool>(ReplayPausedNotifier.new);

class ReplayPausedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool paused) => state = paused;

  void toggle() => state = !state;
}
