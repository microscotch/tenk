import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/widgets/tutorial_overlay.dart';

/// La couche de bulles laisse passer le doigt jusqu'à la seule commande visée,
/// aussi quand elle est posée dans une zone plus petite que l'écran (la fenêtre
/// d'un dialogue, dans les marges de sécurité d'un téléphone à encoche).
void main() {
  testWidgets('dans une zone rognée par les marges de sécurité, tout sauf la commande visée est absorbé', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final target = GlobalKey();
    var targetTaps = 0;
    var neighbourTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 59, bottom: 34)),
          child: Scaffold(
            body: Stack(
              children: [
                // Deux commandes, l'une au-dessus de l'autre : seule la seconde est visée.
                Positioned(
                  left: 100,
                  top: 440,
                  child: ElevatedButton(onPressed: () => neighbourTaps++, child: const Text('voisine')),
                ),
                Positioned(
                  left: 100,
                  top: 520,
                  child: ElevatedButton(key: target, onPressed: () => targetTaps++, child: const Text('visée')),
                ),
                // La couche, comme dans un dialogue : dans la zone sûre seulement.
                Positioned.fill(
                  child: SafeArea(
                    child: TutorialBubbleLayer(step: 'a', anchor: target, text: 'Touchez ici', letThrough: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('voisine'), warnIfMissed: false);
    await tester.tap(find.text('visée'), warnIfMissed: false);

    expect(neighbourTaps, 0, reason: 'la voisine est sous la couche : absorbée');
    expect(targetTaps, 1, reason: 'la commande visée, elle, reçoit le doigt');
  });
}
