import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'state/settings_providers.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/sound_effects.dart';
import 'ui/theme.dart';
import 'ui/widgets/casino_felt_background.dart';

void main() {
  runApp(const ProviderScope(child: Le10000App()));
}

class Le10000App extends ConsumerWidget {
  const Le10000App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Démarre/arrête la musique de fond et active/désactive les effets
    // sonores dès que les préférences changent (y compris au tout premier
    // build, avec les valeurs par défaut).
    ref.listen(settingsProvider, (previous, next) => SoundEffects.instance.applySettings(next));
    SoundEffects.instance.applySettings(ref.watch(settingsProvider));

    return MaterialApp(
      title: 'Le 10000',
      theme: buildAppTheme(),
      builder: (context, child) => Stack(
        children: [
          const CasinoFeltBackground(),
          ?child,
        ],
      ),
      home: const SplashScreen(),
    );
  }
}
