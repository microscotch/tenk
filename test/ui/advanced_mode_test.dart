import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/settings_screen.dart';
import 'package:le10000/ui/widgets/about_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/fake_player_store.dart';

/// Le mode avancé : les options avancées des réglages (temporisations,
/// probabilités, sauvegarde des données) n'existent que lorsqu'il est allumé, ce
/// qui se fait en saisissant le code Konami dans le dialogue « À propos ».
void main() {
  late ProviderContainer container;

  Future<void> pump(WidgetTester tester, Widget home, Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    container = ProviderContainer(overrides: [playerStoreProvider.overrideWithValue(FakePlayerStore())]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('sans mode avancé, les options avancées n\'existent pas', (tester) async {
    await pump(tester, const SettingsScreen(), {});
    expect(container.read(settingsProvider).advancedMode, isFalse);
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Options avancées'), findsNothing);
    expect(find.text('Mode avancé'), findsNothing);
    expect(find.textContaining('probabilit'), findsNothing);
    expect(find.text('Exporter mes données'), findsNothing);
  });

  testWidgets('en mode avancé elles apparaissent, et éteindre le mode les cache', (tester) async {
    await pump(tester, const SettingsScreen(), {'settings.advancedMode': true});
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(find.text('Options avancées'), findsOneWidget);
    expect(find.textContaining('probabilit'), findsWidgets);
    expect(find.text('Exporter mes données'), findsOneWidget);

    await tester.tap(find.text('Mode avancé'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).advancedMode, isFalse);
    expect(find.text('Options avancées'), findsNothing);
  });

  Future<void> openAbout(WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'TenK',
      packageName: 'net.microscotch.tenk',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await pump(
      tester,
      Builder(builder: (context) => TextButton(onPressed: () => showAppAboutDialog(context), child: const Text('à propos'))),
      {},
    );
    await tester.tap(find.text('à propos'));
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester tester, String name) async {
    await tester.tap(find.byKey(ValueKey('konami-$name')));
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> playKonami(WidgetTester tester) async {
    for (final key in ['up', 'up', 'down', 'down', 'left', 'right', 'left', 'right', 'b', 'a', 'start']) {
      await tapKey(tester, key);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('le code Konami sur l\'écran À propos propose le mode avancé ; l\'accepter l\'allume', (tester) async {
    await openAbout(tester);
    expect(container.read(settingsProvider).advancedMode, isFalse);

    await playKonami(tester);
    expect(find.text('Activer le mode avancé ?'), findsOneWidget);
    expect(container.read(settingsProvider).advancedMode, isFalse, reason: 'rien n\'est allumé avant la réponse');

    await tester.tap(find.text('Activer'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).advancedMode, isTrue);
  });

  testWidgets('refuser la proposition laisse l\'application en mode normal', (tester) async {
    await openAbout(tester);
    await playKonami(tester);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).advancedMode, isFalse);
  });

  testWidgets('un code incomplet ou dans le mauvais ordre ne propose rien', (tester) async {
    await openAbout(tester);
    for (final key in ['up', 'down', 'up', 'down', 'left', 'right', 'left', 'right', 'b', 'a', 'start']) {
      await tapKey(tester, key);
    }
    await tester.pumpAndSettle();
    expect(find.text('Activer le mode avancé ?'), findsNothing);
    expect(container.read(settingsProvider).advancedMode, isFalse);
  });
}
