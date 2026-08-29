import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/ai/ai_profiles.dart';
import '../game/dice_off.dart';
import 'game_providers.dart';

final diceOffProvider = NotifierProvider<DiceOffNotifier, DiceOffState?>(DiceOffNotifier.new);

class DiceOffNotifier extends Notifier<DiceOffState?> {
  late GameSetup _setup;

  @override
  DiceOffState? build() => null;

  bool get isPassAndPlayMode => _setup.aiPlayers.isEmpty;
  bool isAiPlayer(int index) => _setup.isAi(index);
  String nameOf(int index) => _setup.playerNames[index];

  void start(GameSetup setup) {
    _setup = setup;
    state = DiceOffState.start(setup.playerNames.length);
  }

  void rollForCurrent() {
    final s = state!;
    final idx = s.nextToRoll!;
    var next = s.rollFor(idx);
    if (next.roundComplete) next = next.resolveRound();
    state = next;
  }

  /// Construit la configuration de partie finale, les joueurs étant
  /// réordonnés pour que le vainqueur du départage commence (index 0).
  GameSetup buildRotatedSetup() {
    final s = state!;
    final winner = s.winnerIndex!;
    final n = _setup.playerNames.length;
    final rotatedNames = [for (var i = 0; i < n; i++) _setup.playerNames[(winner + i) % n]];
    final rotatedAi = <int, AiDifficulty>{};
    _setup.aiPlayers.forEach((origIndex, difficulty) {
      rotatedAi[(origIndex - winner + n) % n] = difficulty;
    });
    return GameSetup(playerNames: rotatedNames, aiPlayers: rotatedAi);
  }
}
