import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';
import 'state/settings_providers.dart';
import 'ui/route_observer.dart';
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

    final languageOverride = ref.watch(settingsProvider).languageOverride;

    return MaterialApp(
      title: 'TenK',
      theme: buildAppTheme(),
      locale: languageOverride == null ? null : Locale(languageOverride),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Le français est la langue d'origine du jeu : c'est le repli si la
      // langue de l'appareil (ou aucune de ses préférences) ne fait partie
      // des langues supportées, plutôt que la première de la liste triée
      // alphabétiquement (le bulgare, sinon).
      localeListResolutionCallback: (locales, supportedLocales) {
        if (locales != null) {
          for (final locale in locales) {
            for (final supported in supportedLocales) {
              if (supported.languageCode == locale.languageCode) return supported;
            }
          }
        }
        return const Locale('fr');
      },
      builder: (context, child) => Stack(
        children: [
          const CasinoFeltBackground(),
          ?child,
        ],
      ),
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}
