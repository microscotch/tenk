import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/sound_effects.dart';

/// Désactive les effets sonores pour toute la suite de tests : `audioplayers`
/// n'a pas de backend dans l'environnement headless de `flutter_test`, et le
/// son n'a de toute façon aucune valeur pour ces tests.
///
/// Force aussi la locale de test en français : la suite fait des dizaines
/// d'assertions sur des libellés français en dur (`find.text('...')`), pour
/// ne pas avoir à les dupliquer par langue. Chaque test doit tout de même
/// fournir `localizationsDelegates`/`supportedLocales` à son `MaterialApp`
/// pour que `AppLocalizations.of(context)` résolve quoi que ce soit.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugDisableSoundEffects();
  final dispatcher = TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher;
  // Les deux : `locale` est le signal legacy encore lu par endroits, mais la
  // résolution de MaterialApp (`basicLocaleListResolution`) part de la liste
  // `locales` — sans elle, la vraie locale de la machine de test l'emporte.
  dispatcher.localeTestValue = const Locale('fr');
  dispatcher.localesTestValue = const [Locale('fr')];
  await testMain();
}
