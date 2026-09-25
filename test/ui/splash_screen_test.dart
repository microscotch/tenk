import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/screens/splash_screen.dart';
import 'package:le10000/ui/widgets/die_widget.dart';

void main() {
  // Chorégraphie : avatar (500 ms), pause (200), « présente » (350), pause
  // (200), puis les dés apparaissent en fondu (400 ms) avant de rouler.
  const diceAppear = Duration(milliseconds: 1250);
  const diceFadeIn = Duration(milliseconds: 400);

  List<DieWidget> dice(WidgetTester tester) => tester.widgetList<DieWidget>(find.byType(DieWidget)).toList();

  double diceOpacity(WidgetTester tester) => tester
      .widget<AnimatedOpacity>(find.ancestor(of: find.byType(Wrap), matching: find.byType(AnimatedOpacity)).first)
      .opacity;

  testWidgets('les dés apparaissent posés, puis roulent une fois le fondu terminé et tombent sur l\'as',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SplashScreen(),
    ));
    await tester.pump();

    expect(diceOpacity(tester), 0, reason: 'les dés ne sont pas encore là');

    await tester.pump(diceAppear);
    expect(diceOpacity(tester), 1, reason: 'le fondu d\'apparition a commencé');
    expect(dice(tester).every((d) => d.rollToken == null), isTrue, reason: 'pendant le fondu, les dés sont posés');
    expect(dice(tester).every((d) => d.value != 1), isTrue, reason: 'ils ne montrent pas déjà l\'as');

    await tester.pump(diceFadeIn - const Duration(milliseconds: 50));
    expect(dice(tester).every((d) => d.rollToken == null), isTrue, reason: 'pas de lancer avant la fin du fondu');

    await tester.pump(const Duration(milliseconds: 50));
    expect(dice(tester), hasLength(5));
    expect(dice(tester).every((d) => d.rollToken != null), isTrue, reason: 'le lancer part à la fin du fondu');
    expect(dice(tester).every((d) => d.value == 1), isTrue, reason: 'chaque dé tombe sur l\'as');

    await tester.pump(DieWidget.maxRollDuration);
    // Démonte l'écran : ses minuteries restantes (navigation) sont annulées.
    await tester.pumpWidget(const SizedBox());
  });
}
