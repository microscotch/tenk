import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_player_store.dart';

/// Le choix du bruit des dés, dans la section Sons des réglages.
void main() {
  late ProviderContainer container;

  Future<void> pumpSettings(WidgetTester tester, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    container = ProviderContainer(overrides: [playerStoreProvider.overrideWithValue(FakePlayerStore())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  SegmentedButton<DiceSoundMode> selector(WidgetTester tester) =>
      tester.widget<SegmentedButton<DiceSoundMode>>(find.byType(SegmentedButton<DiceSoundMode>));

  testWidgets('réaliste par défaut ; « Synthétique » bascule sur le son d\'origine', (tester) async {
    await pumpSettings(tester, {});
    expect(find.text('Bruit des dés'), findsOneWidget);
    expect(selector(tester).selected, {DiceSoundMode.realistic});

    await tester.ensureVisible(find.text('Synthétique'));
    await tester.tap(find.text('Synthétique'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).diceSoundMode, DiceSoundMode.synthetic);
    expect(selector(tester).selected, {DiceSoundMode.synthetic});
  });

  testWidgets('sans effets sonores, le choix est grisé', (tester) async {
    await pumpSettings(tester, {'settings.soundEffectsEnabled': false});
    expect(selector(tester).onSelectionChanged, isNull);
  });

  SegmentedButton<MusicTrack> trackSelector(WidgetTester tester) =>
      tester.widget<SegmentedButton<MusicTrack>>(find.byType(SegmentedButton<MusicTrack>));

  testWidgets('musique : « Next to You » par défaut, grisé tant qu\'elle est coupée, « Originale » la remplace', (tester) async {
    await pumpSettings(tester, {});
    expect(find.text('Boucle de la musique'), findsOneWidget);
    expect(trackSelector(tester).selected, {MusicTrack.nextToYou});
    expect(trackSelector(tester).onSelectionChanged, isNull);

    container.read(settingsProvider.notifier).setMusicEnabled(true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Originale'));
    await tester.tap(find.text('Originale'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).musicTrack, MusicTrack.original);
    container.read(settingsProvider.notifier).setMusicEnabled(false);
  });
}
