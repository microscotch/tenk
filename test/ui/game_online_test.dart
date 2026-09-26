import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_screen.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/scripted_game.dart';

const _token = 'abcdef0123456789abcdef0123456789';
const _names = ['Anna', 'Bob'];
const _setup = GameSetup(playerNames: _names);

/// L'écran de jeu d'une partie en ligne : mes tours sont à moi, ceux de
/// l'autre se regardent.
void main() {
  late FakeTransport transport;
  late ProviderContainer container;

  setUp(() {
    transport = FakeTransport();
    container = ProviderContainer(overrides: [
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(FakeCredentialsStore()),
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(FakePlayerStore()),
    ]);
    addTearDown(container.dispose);
  });

  List<GameAction> fullJournal(int seed) => journalWithFaces(_setup, seed, playScriptedGame(_setup, seed).actions);

  /// Le journal du départ : le départage et le premier tour.
  List<GameAction> opening(List<GameAction> full) =>
      full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);

  /// Le siège du joueur qui ouvre la partie.
  int firstSeat(List<GameAction> journal) => replayGame(_setup, 0, journal).playOrder!.first;

  Future<void> openGame(WidgetTester tester, {required int mySeat, required List<GameAction> journal}) async {
    await container.read(onlineSessionProvider.notifier).join('abcde', _names[mySeat]);
    transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: mySeat));
    transport.current.serverSends(ServerMessage.room(
      code: 'ABCDE',
      phase: RoomPhase.playing,
      seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
      hostSeat: 0,
    ));
    transport.current.serverSends(ServerMessage.snapshot(names: _names, actions: journal));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('au tour de l\'autre : son nom, aucune commande', (tester) async {
    final journal = opening(fullJournal(5));
    final first = firstSeat(journal);
    final me = 1 - first;
    await openGame(tester, mySeat: me, journal: journal);

    expect(find.text('${_names[first]} joue…'), findsOneWidget);
    expect(find.byIcon(Icons.front_hand), findsNothing, reason: 'pas de bouton Stop pour un tour qui n\'est pas le mien');
    expect(container.read(gameProvider.notifier).isMyOnlineTurn, isFalse);
  });

  testWidgets('à mon tour : mes commandes, et « Lancer » demande le lancer au serveur sans rien changer', (tester) async {
    final journal = opening(fullJournal(5));
    final me = firstSeat(journal);
    await openGame(tester, mySeat: me, journal: journal);

    expect(find.textContaining('joue…'), findsNothing);
    expect(find.byIcon(Icons.front_hand), findsOneWidget);
    final before = container.read(gameProvider);

    await tester.tap(find.textContaining('Lancer'));
    await tester.pump();

    expect(transport.current.sent.where((m) => m.type == ClientMessageType.play).map((m) => m.params['intent']), ['roll']);
    expect(identical(container.read(gameProvider), before), isTrue, reason: 'les dés viennent du serveur');
  });

  testWidgets('le lancer que le serveur envoie apparaît chez l\'autre joueur', (tester) async {
    final full = fullJournal(5);
    final journal = opening(full);
    final first = firstSeat(journal);
    await openGame(tester, mySeat: 1 - first, journal: journal);
    final rollIndex = journal.length; // le premier coup après le départ est le lancer
    expect(full[rollIndex].type, GameActionType.roll);

    transport.current.serverSends(ServerMessage.action(seq: rollIndex, action: full[rollIndex]));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(const Duration(seconds: 2));

    expect(container.read(gameProvider)!.activeTurn!.pendingRoll!.faces, full[rollIndex].faces);
    expect(find.text('${_names[first]} joue…'), findsOneWidget);
  });

  testWidgets('le craque d\'un autre joueur se voit sans popup et sans commande', (tester) async {
    // Une partie dont le premier lancer craque.
    int? seed;
    for (var s = 0; s < 300 && seed == null; s++) {
      final full = fullJournal(s);
      final replayed = replayGame(_setup, 0, full.sublist(0, opening(full).length + 1));
      if (replayed.engine!.activeTurn!.busted) seed = s;
    }
    expect(seed, isNotNull, reason: 'aucune seed ne craque au premier lancer');
    final full = fullJournal(seed!);
    final journal = opening(full);
    final first = firstSeat(journal);
    await openGame(tester, mySeat: 1 - first, journal: journal);

    transport.current.serverSends(ServerMessage.action(seq: journal.length, action: full[journal.length]));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump(GameScreen.bustRevealDelay + const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(gameProvider)!.activeTurn!.busted, isTrue);
    expect(find.byType(AlertDialog), findsNothing, reason: 'c\'est à lui d\'acquitter son craque');
    expect(find.text('Craqué !'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.ancestor(of: find.text('Craqué !'), matching: find.byType(FilledButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('connexion perdue : bandeau de reconnexion ; partie suspendue : bandeau d\'absence', (tester) async {
    final journal = opening(fullJournal(5));
    await openGame(tester, mySeat: firstSeat(journal), journal: journal);
    expect(find.text('Connexion perdue, reconnexion…'), findsNothing);
    expect(find.textContaining('suspendue'), findsNothing);

    transport.current.serverSends(ServerMessage.room(
      code: 'ABCDE',
      phase: RoomPhase.suspended,
      seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: false)],
      hostSeat: 0,
    ));
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    expect(find.text('Partie suspendue : un joueur est absent depuis trop longtemps.'), findsOneWidget);
  });

  testWidgets('en ligne, on ne passe jamais l\'appareil', (tester) async {
    final journal = opening(fullJournal(5));
    await openGame(tester, mySeat: firstSeat(journal), journal: journal);
    expect(container.read(gameProvider.notifier).shouldShowPassDevice(0), isFalse);
  });
}
