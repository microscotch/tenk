import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Déroule l'historique de la partie depuis la barre du bas de l'écran de jeu
/// (le journal n'est plus affiché en permanence).
Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('history-bar')));
  await tester.pumpAndSettle();
}

/// Referme l'historique déroulé par [openHistory].
Future<void> closeHistory(WidgetTester tester) async {
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();
}

/// [finder], limité au panneau d'historique déroulé : la barre du bas répète
/// la dernière entrée, qu'il ne faut pas compter deux fois.
Finder inHistory(Finder finder) => find.descendant(of: find.byType(BottomSheet), matching: finder);

/// Déroule l'historique, y vérifie [matcher] pour les entrées contenant [text],
/// puis le referme.
Future<void> expectInHistory(WidgetTester tester, String text, Matcher matcher, {String? reason}) async {
  await openHistory(tester);
  expect(inHistory(find.textContaining(text)), matcher, reason: reason);
  await closeHistory(tester);
}
