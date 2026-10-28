import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/theme_choice_screen.dart';
import 'package:le10000/ui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('la musique est désactivée par défaut et le thème n\'est pas choisi', () {
    const settings = AppSettings();
    expect(settings.musicEnabled, isFalse);
    expect(settings.themeChoice, isNull);
  });

  test('le thème choisi est relu, un thème inconnu compte pour non choisi', () async {
    SharedPreferences.setMockInitialValues({'settings.themeChoice': 'light'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(settingsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(settingsProvider).themeChoice, ThemeChoice.light);
    expect(container.read(settingsProvider).musicEnabled, isFalse);

    SharedPreferences.setMockInitialValues({'settings.themeChoice': 'neon'});
    final other = ProviderContainer();
    addTearDown(other.dispose);
    other.read(settingsProvider);
    await Future<void>.delayed(Duration.zero);
    expect(other.read(settingsProvider).themeChoice, isNull);
  });

  test('le thème clair a un fond et des couleurs de sens plus sombres que le thème sombre', () {
    final light = themeFor(ThemeChoice.light);
    final dark = themeFor(null);
    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<TableColors>()!.feltCenter.computeLuminance(), greaterThan(0.6));
    expect(dark.extension<TableColors>()!.feltCenter.computeLuminance(), lessThan(0.1));
    expect(light.extension<TableColors>()!.positive.computeLuminance(),
        lessThan(dark.extension<TableColors>()!.positive.computeLuminance()));
  });

  testWidgets('toucher une vignette applique le thème, « Continuer » le garde et ouvre la suite', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: Consumer(
        builder: (context, ref, _) => MaterialApp(
          theme: themeFor(ref.watch(settingsProvider).themeChoice),
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ThemeChoiceScreen(next: Scaffold(body: Text('suite'))),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clair'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).themeChoice, ThemeChoice.light);
    expect(Theme.of(tester.element(find.byType(ThemeChoiceScreen))).brightness, Brightness.light);

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('suite'), findsOneWidget);
  });
}
