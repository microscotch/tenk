import 'dart:async';

import 'package:le10000/ui/sound_effects.dart';

/// Désactive les effets sonores pour toute la suite de tests : `audioplayers`
/// n'a pas de backend dans l'environnement headless de `flutter_test`, et le
/// son n'a de toute façon aucune valeur pour ces tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugDisableSoundEffects();
  await testMain();
}
