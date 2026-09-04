import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/settings_providers.dart';
import 'package:le10000/ui/screens/new_game_screen.dart';

void main() {
  testWidgets('un tap sur le nom en lecture seule d\'un joueur humain le rend éditable', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Nom déjà connu : évite la boîte de dialogue "Votre nom ?" (montée en
    // fonction du cas vide dans un autre test ci-dessous), pour se
    // concentrer ici uniquement sur le bug du champ non éditable.
    container.read(settingsProvider.notifier).setPlayerName('Zaphod');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: NewGameScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Avant tout tap, le champ du joueur 1 est rendu en lecture seule (pas
    // de TextField) : c'était justement le bug -- le FocusNode de ce rendu
    // n'était jamais attaché à l'arbre de focus, donc requestFocus() au tap
    // ne faisait rien et le champ ne devenait jamais éditable.
    expect(find.text('Zaphod'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Zaphod'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget,
        reason: 'un tap sur le nom en lecture seule doit basculer le champ vers un vrai TextField éditable');

    await tester.enterText(find.byType(TextField), 'Arthur Dent');
    await tester.pump();

    expect(find.text('Arthur Dent'), findsOneWidget,
        reason: 'le nouveau nom tapé doit être pris en compte par le champ');
  });

  testWidgets('un joueur sans nom de propriétaire enregistré ne fait pas planter l\'écran', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // playerName reste '' (valeur par défaut) : c'est justement le cas qui
    // faisait planter l'écran -- initState() appelait AppLocalizations.of(
    // context) pour le nom par défaut du joueur 1, ce que Flutter interdit
    // avant la fin d'initState().

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: NewGameScreen(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    // Un seul pump (pas pumpAndSettle) : suffit à passer initState/
    // didChangeDependencies/build sans attendre la fin de l'animation de la
    // boîte de dialogue "Votre nom ?" qui s'ouvre juste après.
    await tester.pump();

    expect(tester.takeException(), isNull,
        reason: 'monter l\'écran sans nom de propriétaire enregistré ne doit jamais planter');
    expect(find.text('Joueur 1'), findsOneWidget,
        reason: 'le nom par défaut localisé doit malgré tout apparaître dans le champ du joueur 1');
  });
}
