import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/screens/acknowledgements_screen.dart';
import 'package:le10000/ui/widgets/about_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Le bouton « Remerciements » du dialogue « À propos », et l'écran qu'il ouvre.
void main() {
  Future<void> pumpAbout(WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'TenK',
      packageName: 'net.microscotch.games.tenk',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(child: TextButton(onPressed: () => showAppAboutDialog(context), child: const Text('ouvrir'))),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('le dialogue propose « Remerciements », qui ouvre l\'écran des beta-testeurs', (tester) async {
    await pumpAbout(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('about-acknowledgements')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing, reason: 'le dialogue se referme');
    expect(find.byType(AcknowledgementsScreen), findsOneWidget);
    expect(
      find.text('Un grand merci à tous les bêta-testeurs de la première heure pour leurs remarques et conseils, en particulier :'),
      findsOneWidget,
    );
    expect(AcknowledgementsScreen.betaTesters, [
      'Alex', 'Cam', 'Chris', 'Deepsound', 'Finette', 'Fluo', 'Greg', 'IvenKor', 'Kali78', 'Nico', 'Popoche', 'R1', 'Sam', 'Seb', 'Town God', //
    ]);
    final sorted = [...AcknowledgementsScreen.betaTesters]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    expect(AcknowledgementsScreen.betaTesters, sorted, reason: 'par ordre alphabétique');
    expect(find.text('Rrr'), findsNothing);
    for (final name in AcknowledgementsScreen.betaTesters) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
  });

  testWidgets('le retour ramène à la page d\'où l\'on est venu', (tester) async {
    await pumpAbout(tester);
    await tester.tap(find.byKey(const ValueKey('about-acknowledgements')));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(AcknowledgementsScreen), findsNothing);
    expect(find.text('ouvrir'), findsOneWidget);
  });
}
