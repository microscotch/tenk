import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Multiplicateur de vitesse du rejeu spectateur (x1/x2/x4), partagé entre
/// l'écran de tirage au sort et l'écran de jeu en mode rejeu — le délai
/// effectif entre deux actions divise `aiMessageDelay` (réglages) par cette
/// valeur. Valeurs valides : 1, 2, 4.
final replaySpeedProvider = NotifierProvider<ReplaySpeedNotifier, int>(ReplaySpeedNotifier.new);

class ReplaySpeedNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void set(int speed) => state = speed;
}
