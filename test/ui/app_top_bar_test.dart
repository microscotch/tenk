import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/widgets/app_top_bar.dart';

/// La barre du haut commune : pas de flèche de retour sur Android, où le retour
/// système s'en charge ; la flèche reste là où il n'y en a pas (iOS, bureau).
void main() {
  /// Un écran d'accueil qui empile, dès le premier frame, un écran doté de la
  /// barre commune.
  Future<void> pumpPushedScreen(
    WidgetTester tester, {
    required TargetPlatform platform,
    bool automaticallyImplyLeading = true,
    ThemeData? theme,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: (theme ?? ThemeData()).copyWith(platform: platform),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppTopBar(
                    title: const Text('Écran empilé'),
                    automaticallyImplyLeading: automaticallyImplyLeading,
                  ),
                  body: const SizedBox(),
                ),
              )),
              child: const Text('ACCUEIL'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ACCUEIL'));
    await tester.pumpAndSettle();
    expect(find.text('Écran empilé'), findsOneWidget);
  }

  testWidgets('Android : pas de flèche, le retour système ramène à l\'écran d\'avant', (tester) async {
    await pumpPushedScreen(tester, platform: TargetPlatform.android);

    expect(find.byType(BackButton), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Écran empilé'), findsNothing);
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('iOS : la flèche est là, faute de retour système', (tester) async {
    await pumpPushedScreen(tester, platform: TargetPlatform.iOS);

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('ACCUEIL'), findsOneWidget);
  });

  testWidgets('bureau : la flèche est là aussi', (tester) async {
    await pumpPushedScreen(tester, platform: TargetPlatform.linux);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('un écran qui écarte la flèche l\'écarte partout, iOS compris', (tester) async {
    await pumpPushedScreen(tester, platform: TargetPlatform.iOS, automaticallyImplyLeading: false);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('la barre prend la hauteur du thème, comme un AppBar', (tester) async {
    await pumpPushedScreen(
      tester,
      platform: TargetPlatform.android,
      theme: ThemeData(appBarTheme: const AppBarTheme(toolbarHeight: 72)),
    );
    expect(tester.getSize(find.byType(AppBar)).height, 72);
  });

  test('aucun écran n\'utilise AppBar directement : tous passent par AppTopBar', () {
    // Garde-fou pour les écrans à venir : un `AppBar(` direct afficherait de
    // nouveau la flèche de retour sur Android.
    final offenders = <String>[];
    for (final file in Directory('lib/ui').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') || file.path.endsWith('app_top_bar.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final code = lines[i].split('//').first;
        if (RegExp(r'(?<![A-Za-z_])AppBar\(').hasMatch(code)) offenders.add('${file.path}:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'utiliser AppTopBar (lib/ui/widgets/app_top_bar.dart) à la place');
  });
}
