import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/player.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/ui/screens/score_grid_screen.dart';

Player _player(String name, List<int> gains) {
  var p = Player(name: name);
  for (final g in gains) {
    p = p.applySuccessfulTurn(g);
  }
  return p;
}

/// Les valeurs de chaque rangée de l'échelle : (gauche, droite), null pour un blanc.
List<(int?, int?)> _values(Player left, Player right) => [for (final r in ladderRows(left, right)) (r.left?.value, r.right?.value)];

Future<void> _pump(WidgetTester tester, Widget screen) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(1000, 800));
  await tester.pumpWidget(
    MaterialApp(
      home: screen,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ladderRows', () {
    test('une rangée par valeur, la plus haute en haut, les valeurs égales face à face, un blanc sinon', () {
      final a = _player('A', [500, 200, 500]); // 0, 500, 700, 1200
      final b = _player('B', [500, 400, 300]); // 0, 500, 900, 1200

      expect(_values(a, b), [(1200, 1200), (null, 900), (700, null), (500, 500), (0, 0)]);
    });

    test('la ligne courante de chacun est repérée', () {
      final a = _player('A', [500, 200]); // 0, 500, 700 (courante)
      final b = _player('B', [500, 400]); // 0, 500, 900 (courante)

      final rows = ladderRows(a, b);

      expect([for (final r in rows) (r.leftCurrent, r.rightCurrent)], [(false, true), (true, false), (false, false), (false, false)]);
    });

    test('une valeur présente deux fois chez un joueur prend deux rangées, la plus récente d\'abord', () {
      // 500 tiretée puis barrée (retour à 0), puis refaite : deux lignes de 500, dont la première est barrée.
      var a = _player('A', [500]).applyBust().applyBust().applySuccessfulTurn(500);
      expect(a.grid.where((e) => e.value == 500).length, 2, reason: 'le cas de test doit bien avoir deux lignes de 500');
      final b = _player('B', [500]); // 0, 500

      final rows = ladderRows(a, b);

      expect([for (final r in rows) (r.left?.value, r.right?.value)], [(500, 500), (500, null), (0, 0)]);
      expect(rows[0].left!.isBarred, isFalse, reason: 'la plus récente (la ligne vivante) d\'abord');
      expect(rows[1].left!.isBarred, isTrue);
    });
  });

  group('grille en mode comparaison', () {
    testWidgets('deux lignes de même valeur sont à la même hauteur, une valeur seule laisse un blanc en face', (tester) async {
      final a = _player('Alice', [500, 200, 500]); // 0, 500, 700, 1200
      final b = _player('Bob', [500, 400, 300]); // 0, 500, 900, 1200
      await _pump(tester, ScoreGridScreen(players: [a, b], reference: a, potentialTotal: 1200));

      final twelve = find.text('1200');
      expect(twelve, findsNWidgets(2));
      expect(tester.getCenter(twelve.first).dy, tester.getCenter(twelve.last).dy);
      expect(tester.getCenter(twelve.first).dx, lessThan(tester.getCenter(twelve.last).dx), reason: 'la référence est à gauche');

      final five = find.text('500');
      expect(tester.getCenter(five.first).dy, tester.getCenter(five.last).dy);

      // 900 n'est qu'à Bob, 700 qu'à Alice : rangées distinctes, rangées rangées par valeur.
      final y900 = tester.getCenter(find.text('900')).dy;
      final y700 = tester.getCenter(find.text('700')).dy;
      expect(y900, isNot(y700));
      expect(tester.getCenter(twelve.first).dy, lessThan(y900));
      expect(y900, lessThan(y700));
      expect(y700, lessThan(tester.getCenter(five.first).dy));
    });

    testWidgets('quand les scores sont éloignés, la ligne courante de la référence est ramenée au milieu', (tester) async {
      final me = _player('Alice', [5000]); // 0, 5000 (courante)
      // Bob : 40 lignes de 0 à 10000, la référence tombe au milieu de l'échelle.
      final bob = _player('Bob', List.filled(40, 250));
      await _pump(tester, ScoreGridScreen(players: [me, bob], reference: me, potentialTotal: 5000));

      final body = tester.getRect(find.byType(SingleChildScrollView));
      final mine = find.text('5000').first; // la colonne de gauche
      expect(tester.getCenter(mine).dx, lessThan(500));
      expect(tester.getCenter(mine).dy, closeTo(body.center.dy, 30), reason: 'au milieu de la zone qui défile');
    });

    testWidgets('en haut de l\'échelle, aucun espace n\'est ajouté pour forcer le centrage', (tester) async {
      final me = _player('Alice', [20000 ~/ 2]); // 0, 10000 (courante, la plus haute)
      final bob = _player('Bob', List.filled(40, 200)); // 0 .. 8000, beaucoup de lignes dessous
      await _pump(tester, ScoreGridScreen(players: [me, bob], reference: me, potentialTotal: 10000));

      final body = tester.getRect(find.byType(SingleChildScrollView));
      final top = tester.getTopLeft(find.byType(Container).evaluate().map((e) => find.byWidget(e.widget)).first);
      expect(top.dy, closeTo(body.top, 1), reason: 'la plus haute ligne reste collée en haut : le défilement s\'arrête là');
      expect(tester.getCenter(find.text('10000').first).dy, lessThan(body.top + 40));
    });

    testWidgets('quand tout tient à l\'écran, rien ne défile : la liste commence en haut', (tester) async {
      final a = _player('Alice', [500]);
      final b = _player('Bob', [600]);
      await _pump(tester, ScoreGridScreen(players: [a, b], reference: a, potentialTotal: 500));

      final body = tester.getRect(find.byType(SingleChildScrollView));
      expect(tester.getCenter(find.text('600')).dy, lessThan(body.top + 40), reason: 'la plus haute ligne est tout en haut');
    });
  });
}
