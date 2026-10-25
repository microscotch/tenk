import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/widgets/about_dialog.dart';
import 'package:le10000/ui/widgets/die_widget.dart';
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

  testWidgets('cinq as en croix sous « 10K » : un, trois, un, chaque ligne centrée', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    final dice = find.byType(DieWidget);
    expect(dice, findsNWidgets(5));
    for (final die in tester.widgetList<DieWidget>(dice)) {
      expect(die.value, 1);
    }

    // Les dés par ligne (même ordonnée de centre) : 1, 3, 1, sous « 10K ».
    final centers = [for (var i = 0; i < 5; i++) tester.getCenter(dice.at(i))];
    final lines = <double, List<double>>{};
    for (final c in centers) {
      lines.putIfAbsent(c.dy, () => []).add(c.dx);
    }
    final ordered = lines.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    expect(ordered.map((e) => e.value.length), [1, 3, 1]);
    final axis = tester.getCenter(find.text('10K')).dx;
    for (final line in ordered) {
      final xs = line.value;
      expect((xs.reduce((a, b) => a + b) / xs.length), closeTo(axis, 0.5), reason: 'ligne centrée');
    }
    expect(ordered.first.key, greaterThan(tester.getCenter(find.text('10K')).dy));
  });

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
