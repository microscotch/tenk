import 'dart:math';

/// Lance [count] dés à 6 faces. Le générateur aléatoire est injectable pour
/// permettre des tests déterministes du moteur de jeu.
List<int> rollDice(int count, [Random? random]) {
  assert(count >= 1 && count <= 5);
  final rng = random ?? Random();
  return List.generate(count, (_) => rng.nextInt(6) + 1);
}
