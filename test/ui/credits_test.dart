import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/widgets/about_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Le bouton « Crédits » du dialogue « À propos », la fenêtre qu'il ouvre et le
/// fichier Markdown qu'elle affiche.
void main() {
  Future<void> pumpAbout(WidgetTester tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'TenK',
      packageName: 'net.microscotch.games.tenk',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(onPressed: () => showAppAboutDialog(context), child: const Text('ouvrir')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('les trois boutons du dialogue sont ronds, alignés, et portent leur nom en infobulle', (tester) async {
    await pumpAbout(tester);
    final keys = ['about-acknowledgements', 'about-credits', 'about-close'];
    final centres = [for (final k in keys) tester.getCenter(find.byKey(ValueKey(k)))];
    expect(centres.map((c) => c.dy).toSet().length, 1, reason: 'sur une même ligne');
    expect(centres[0].dx < centres[1].dx && centres[1].dx < centres[2].dx, isTrue);
    expect(find.text('\u{1F64F}'), findsOneWidget);
    expect(find.text('\u00A9\uFE0F'), findsOneWidget);
    expect(find.text('\u274C'), findsOneWidget);
    expect(find.byTooltip('Remerciements'), findsOneWidget);
    expect(find.byTooltip('Crédits'), findsOneWidget);
    expect(find.byTooltip('Fermer'), findsOneWidget);
  });

  testWidgets('« Crédits » ouvre la fenêtre par-dessus le dialogue, qui reste en place', (tester) async {
    await pumpAbout(tester);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('about-credits')));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNWidgets(2));
    expect(find.byKey(const ValueKey('credits-markdown')), findsOneWidget);
    expect(find.text('Libraries'), findsOneWidget, reason: 'le contenu du fichier Markdown est rendu');
    expect(find.text('flutter_localizations'), findsOneWidget);

    // Fermer la fenêtre des crédits laisse le dialogue « À propos ».
    await tester.tap(find.text('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const ValueKey('credits-markdown')), findsNothing);
  });

  test('chaque bibliothèque de l\'application a son paragraphe dans les crédits', () {
    final pubspec = File('pubspec.yaml').readAsLinesSync();
    final start = pubspec.indexOf('dependencies:');
    final end = pubspec.indexOf('dev_dependencies:');
    final dependencies = [
      for (final line in pubspec.sublist(start + 1, end))
        if (RegExp(r'^  [a-z_0-9]+:').hasMatch(line)) line.trim().split(':').first,
    ];
    expect(dependencies, isNotEmpty);

    final credits = File('assets/credits.md').readAsStringSync();
    final headings = RegExp(r'^### (.+)$', multiLine: true).allMatches(credits).map((m) => m.group(1)!.trim()).toSet();
    // « flutter » est la bibliothèque Flutter elle-même.
    for (final name in dependencies) {
      expect(headings, contains(name == 'flutter' ? 'Flutter' : name), reason: '$name manque aux crédits');
    }
  });
}
