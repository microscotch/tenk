import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/widgets/about_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    // PackageInfo.fromPlatform() passe par un MethodChannel indisponible en
    // test widget : setMockInitialValues le court-circuite avec des valeurs
    // fixes, comme prévu par le package pour ce cas d'usage.
    PackageInfo.setMockInitialValues(
      appName: 'TenK',
      packageName: 'net.microscotch.games.tenk',
      version: '1.0.0',
      buildNumber: '17',
      buildSignature: '',
    );
  });

  Widget wrap() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showAppAboutDialog(context),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'reprend le contenu de l\'écran d\'introduction et ajoute la version (avec le code de version)',
    (tester) async {
      await tester.pumpWidget(wrap());
      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('10K'), findsOneWidget);
      expect(find.textContaining(kAppTagline), findsOneWidget);
      expect(find.textContaining('1.0.0'), findsOneWidget, reason: 'numéro de version');
      expect(find.textContaining('17'), findsOneWidget, reason: 'code de version (buildNumber)');
    },
  );

  testWidgets('le bouton Fermer ferme le dialogue', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    expect(find.text('10K'), findsOneWidget);

    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();

    expect(find.text('10K'), findsNothing);
  });
}
