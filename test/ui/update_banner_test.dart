import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/state/update_check.dart';
import 'package:le10000/ui/route_observer.dart';
import 'package:le10000/ui/screens/setup_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/fake_update_check.dart';

/// Le bandeau de l'accueil qui annonce un build plus récent sur le store.
void main() {
  Future<FakeUpdateCheckEnvironment> pumpHome(WidgetTester tester, FakeUpdateCheckEnvironment environment) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateCheckEnvironmentProvider.overrideWithValue(environment),
          gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
          archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
          playerStoreProvider.overrideWithValue(FakePlayerStore()),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorObservers: [routeObserver],
          home: const SetupScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return environment;
  }

  testWidgets('un build plus récent est annoncé à l\'accueil', (tester) async {
    await pumpHome(tester, FakeUpdateCheckEnvironment(installed: 94, latest: latestJson(android: 95)));

    expect(find.text('Une nouvelle version est disponible (1.0.0, build 95).'), findsOneWidget);
    expect(find.text('Mettre à jour'), findsOneWidget);
  });

  testWidgets('« Plus tard » retire le bandeau et retient le build', (tester) async {
    final environment = await pumpHome(
      tester,
      FakeUpdateCheckEnvironment(installed: 94, latest: latestJson(android: 95)),
    );

    await tester.tap(find.text('Plus tard'));
    await tester.pumpAndSettle();

    expect(find.text('Mettre à jour'), findsNothing);
    expect(environment.dismissed, 95);
  });

  testWidgets('rien quand l\'application est à jour', (tester) async {
    await pumpHome(tester, FakeUpdateCheckEnvironment(installed: 95, latest: latestJson(android: 95)));

    expect(find.text('Mettre à jour'), findsNothing);
  });

  testWidgets('rien sur une plateforme sans store', (tester) async {
    await pumpHome(tester, FakeUpdateCheckEnvironment(platform: null, installed: 94, latest: latestJson(android: 95)));

    expect(find.text('Mettre à jour'), findsNothing);
  });
}
