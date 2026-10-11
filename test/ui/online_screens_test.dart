import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/game/game_recording.dart';
import 'package:le10000/game/online/protocol.dart';
import 'package:le10000/game/player_profile.dart';
import 'package:le10000/game/turn_state.dart';
import 'package:le10000/l10n/generated/app_localizations.dart';
import 'package:le10000/state/game_providers.dart';
import 'package:le10000/state/game_save_store.dart';
import 'package:le10000/state/online_providers.dart';
import 'package:le10000/state/online_transport.dart';
import 'package:le10000/state/player_store.dart';
import 'package:le10000/ui/screens/game_over_screen.dart';
import 'package:le10000/ui/screens/game_screen.dart';
import 'package:le10000/ui/screens/online_dice_off_screen.dart';
import 'package:le10000/ui/screens/online_entry_screen.dart';
import 'package:le10000/ui/screens/online_room_screen.dart';
import 'package:le10000/ui/share.dart';
import 'package:le10000/ui/widgets/emotes.dart';
import 'package:le10000/ui/widgets/player_avatar.dart';

import '../test_helpers/fake_game_save_store.dart';
import '../test_helpers/fake_online.dart';
import '../test_helpers/fake_player_store.dart';
import '../test_helpers/my_profile.dart';
import '../test_helpers/scripted_game.dart';
import '../test_helpers/history.dart';

const _token = 'abcdef0123456789abcdef0123456789';

/// Le journal de départ d'une partie à deux (départage et premier tour).
List<GameAction> _startedJournal() {
  const setup = GameSetup(playerNames: ['Anna', 'Bob']);
  final full = journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);
  return full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);
}

void main() {
  late FakeTransport transport;
  late FakeCredentialsStore credentials;
  late ProviderContainer container;
  late List<String> shared;
  late bool shareFails;
  late FakePlayerStore players;

  setUp(() async {
    players = FakePlayerStore();
    await seedMyProfile(players, PlayerProfile.create(name: 'Anna'));
    shared = [];
    shareFails = false;
    transport = FakeTransport();
    credentials = FakeCredentialsStore();
    container = ProviderContainer(overrides: [
      onlineTransportProvider.overrideWithValue(transport),
      onlineCredentialsStoreProvider.overrideWithValue(credentials),
      onlineServerUrlProvider.overrideWithValue('ws://test/ws'),
      gameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      archivedGameSaveStoreProvider.overrideWithValue(FakeGameSaveStore()),
      playerStoreProvider.overrideWithValue(players),
      shareTextProvider.overrideWithValue((text, {origin}) async {
        if (shareFails) throw StateError('pas de feuille de partage');
        shared.add(text);
      }),
    ]);
    addTearDown(container.dispose);
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) => tester
      .widget<ButtonStyleButton>(find.ancestor(of: find.text(label), matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)))
      .onPressed != null;

  /// Le serveur répond à la création d'un salon : on y est l'hôte, seul.
  Future<void> serverOpensRoom(WidgetTester tester, {int seat = 0, List<String> names = const ['Anna']}) async {
    transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: seat));
    transport.current.serverSends(ServerMessage.room(
      code: 'ABCDE',
      phase: RoomPhase.lobby,
      seats: [for (final n in names) SeatInfo(name: n, connected: true)],
      hostSeat: 0,
    ));
    await tester.pumpAndSettle();
  }

  group('entrée', () {
    testWidgets('créer un salon envoie le nom du profil, sans rien saisir', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      expect(find.text('Vous jouez sous le nom « Anna »'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Votre pseudo'), findsNothing);
      expect(enabled(tester, 'Créer un salon'), isTrue);

      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.create);
      expect(transport.current.lastSent!.params['name'], 'Anna');
    });

    testWidgets('le surnom du profil passe avant son nom', (tester) async {
      final me = (await players.list()).single;
      await players.write(me.copyWith(nickname: 'Nana'));
      await pump(tester, const OnlineEntryScreen());

      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'abcde');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.params['name'], 'Nana');
    });

    testWidgets('un nom de profil que le serveur refuserait bloque, avec de quoi le corriger', (tester) async {
      final me = (await players.list()).single;
      await players.write(me.copyWith(nickname: 'Un surnom beaucoup trop long'));
      await pump(tester, const OnlineEntryScreen());

      expect(find.textContaining('20 caractères au plus'), findsOneWidget);
      expect(enabled(tester, 'Créer un salon'), isFalse);
      expect(enabled(tester, 'Modifier mon profil'), isTrue);
    });

    testWidgets('rejoindre demande un code complet, envoyé en majuscules', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'abc');
      await tester.pump();
      expect(enabled(tester, 'Rejoindre'), isFalse);

      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'abcde');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.join);
      expect(transport.current.lastSent!.params['code'], 'ABCDE');
    });

    testWidgets('une erreur du serveur s\'affiche ; un coup refusé ne dit rien', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.enterText(find.widgetWithText(TextField, 'Code du salon'), 'ZZZZZ');
      await tester.pump();
      await tester.tap(find.text('Rejoindre'));
      await tester.pumpAndSettle();

      transport.current.serverSends(ServerMessage.error(ErrorCode.illegalMove));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      transport.current.serverSends(ServerMessage.error(ErrorCode.roomNotFound));
      await tester.pumpAndSettle();
      expect(find.text('Aucun salon avec ce code.'), findsOneWidget);
    });

    testWidgets('un serveur injoignable le dit', (tester) async {
      transport.unreachable = true;
      await pump(tester, const OnlineEntryScreen());
      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      expect(find.text('Serveur injoignable.'), findsOneWidget);
    });

    testWidgets('le salon s\'ouvre dès que le serveur l\'a créé', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      await tester.tap(find.text('Créer un salon'));
      await tester.pumpAndSettle();

      await serverOpensRoom(tester);

      expect(find.byType(OnlineRoomScreen), findsOneWidget);
      expect(find.text('ABCDE'), findsOneWidget);
    });

    /// Une partie à deux jouée jusqu'au bout, telle que le serveur l'aurait écrite.
    List<GameAction> finishedJournal() {
      const setup = GameSetup(playerNames: ['Anna', 'Bob']);
      return journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);
    }

    /// Le serveur annonce que la partie du salon est terminée.
    void serverEndsGame() => transport.current.serverSends(ServerMessage.room(
          code: 'ABCDE',
          phase: RoomPhase.over,
          seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
          hostSeat: 0,
        ));

    testWidgets('après une partie terminée, l\'entrée ne propose pas de la reprendre : elle quitte son salon', (tester) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', 'Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: finishedJournal()));
      serverEndsGame();
      await tester.pump(const Duration(milliseconds: 20));
      expect(container.read(onlineSessionProvider).phase, RoomPhase.over, reason: 'prémisse : partie finie, salon encore là');

      await pump(tester, const OnlineEntryScreen());

      expect(find.text('Reprendre la partie en ligne'), findsNothing);
      expect(find.text('Créer un salon'), findsOneWidget);
      expect(transport.channels.first.sent.last.type, ClientMessageType.leave, reason: 'le siège est libéré');
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
      expect(container.read(gameProvider.notifier).isOnline, isFalse);
      expect(credentials.saved, isNull);
    });

    testWidgets('reprendre une place dont la partie s\'est finie entre-temps : on en sort, sans écran qui attend', (tester) async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: _token);
      await pump(tester, const OnlineEntryScreen());

      await tester.tap(find.text('Reprendre la partie en ligne'));
      await tester.pump();
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: finishedJournal()));
      serverEndsGame();
      await tester.pumpAndSettle();

      expect(find.byType(OnlineDiceOffScreen), findsNothing);
      expect(find.byType(GameScreen), findsNothing);
      expect(find.text('Créer un salon'), findsOneWidget);
      expect(transport.current.sent.last.type, ClientMessageType.leave);
    });

    testWidgets('ouvrir l\'entrée ne se connecte à rien : rien à faire tant qu\'on n\'a rien demandé', (tester) async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: _token);
      await pump(tester, const OnlineEntryScreen());
      expect(transport.channels, isEmpty);
    });

    testWidgets('une place gardée se propose, et se retrouve d\'un tap', (tester) async {
      credentials.saved = const OnlineCredentials(url: 'ws://test/ws', code: 'ABCDE', token: _token);
      await pump(tester, const OnlineEntryScreen());

      expect(find.text('Reprendre la partie en ligne'), findsOneWidget);
      await tester.tap(find.text('Reprendre la partie en ligne'));
      await tester.pumpAndSettle();

      expect(transport.current.lastSent!.type, ClientMessageType.rejoin);
      expect(transport.current.lastSent!.params['token'], _token);
    });

    testWidgets('sans place gardée, rien à reprendre', (tester) async {
      await pump(tester, const OnlineEntryScreen());
      expect(find.text('Reprendre la partie en ligne'), findsNothing);
    });

    testWidgets('face à un serveur sans bots, quitter une partie commencée garde sa place, comme le dit la fenêtre',
        (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      transport.current.serverSends(
        ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0, features: const [keepSelectionFeature, emotesFeature]),
      );
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: _startedJournal()));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await pump(tester, const OnlineEntryScreen());

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(credentials.saved, isNotNull, reason: 'le jeton reste : la partie attend son retour');
      expect(transport.channels.first.sent.any((m) => m.type == ClientMessageType.leave), isFalse);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
      expect(find.text('Reprendre la partie en ligne'), findsOneWidget, reason: 'et on peut la retrouver');
    });

    testWidgets('quitter une partie commencée la quitte pour de bon : un bot prend la place, comme le dit la fenêtre',
        (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: _startedJournal()));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await pump(tester, const OnlineEntryScreen());

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      expect(find.textContaining('un bot jouera à votre place'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(credentials.saved, isNull, reason: 'la place ne se reprend plus');
      expect(transport.channels.first.sent.any((m) => m.type == ClientMessageType.leave), isTrue);
      expect(find.text('Reprendre la partie en ligne'), findsNothing);
    });

    testWidgets('une partie en cours se retrouve ou se quitte, sans en ouvrir une seconde', (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      await serverOpensRoom(tester);
      await pump(tester, const OnlineEntryScreen());

      expect(find.text('Reprendre la partie en ligne'), findsOneWidget);
      expect(find.text('Créer un salon'), findsNothing);

      await tester.tap(find.text('Quitter'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.pumpAndSettle();
      // Fermer la connexion passe par des futures que le temps simulé du test
      // ne fait pas avancer : on laisse le vrai temps s'écouler.
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();

      expect(transport.channels.first.sent.last.type, ClientMessageType.leave);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
      expect(find.text('Créer un salon'), findsOneWidget);
    });
  });

  group('salon', () {
    Future<void> inRoom(WidgetTester tester, {required int seat, required List<String> names}) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', names[seat]);
      await pump(tester, const OnlineRoomScreen());
      await serverOpensRoom(tester, seat: seat, names: names);
    }

    testWidgets('l\'hôte ne peut lancer qu\'à deux joueurs connectés', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      expect(enabled(tester, 'Commencer la partie'), isFalse);
      expect(find.text('Il faut au moins 2 joueurs, tous connectés.'), findsOneWidget);

      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.pumpAndSettle();
      expect(enabled(tester, 'Commencer la partie'), isTrue);

      await tester.tap(find.text('Commencer la partie'));
      await tester.pumpAndSettle();
      expect(transport.current.lastSent!.type, ClientMessageType.start);
    });

    testWidgets('une connexion perdue (partage du code) : un bandeau, pas un message par tentative', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      transport.unreachable = true;

      await transport.current.serverDrops();
      // Plusieurs tentatives de reconnexion, toutes ratées (1, 2, 4, 8 s…).
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(seconds: 5));
      }

      expect(find.text('Connexion perdue, reconnexion…'), findsOneWidget);
      expect(find.text('Serveur injoignable.'), findsNothing);
      expect(transport.channels.length, 1, reason: 'les tentatives échouent avant d\'ouvrir un canal');

      // Le réseau revient : le bandeau s'en va.
      transport.unreachable = false;
      await tester.pump(const Duration(seconds: 16));
      expect(transport.channels.length, 2);
      expect(transport.current.sent.single.type, ClientMessageType.rejoin);
      await tester.pumpAndSettle();
      expect(find.text('Connexion perdue, reconnexion…'), findsNothing);
    });

    testWidgets('le code se partage par la feuille de partage du système', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);

      await tester.tap(find.text('Partager le code'));
      await tester.pumpAndSettle();

      expect(shared, ['Rejoins ma partie de Le 10000 en ligne ! Code du salon : ABCDE\nhttps://tenk.microscotch.net/j/ABCDE']);
    });

    testWidgets('sans feuille de partage, le message est copié dans le presse-papiers', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      shareFails = true;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.tap(find.text('Partager le code'));
      await tester.pumpAndSettle();

      expect(shared, isEmpty);
      expect(copied, 'Rejoins ma partie de Le 10000 en ligne ! Code du salon : ABCDE\nhttps://tenk.microscotch.net/j/ABCDE');
    });

    testWidgets('un joueur déconnecté empêche le lancement et se signale', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.lobby,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: false)],
        hostSeat: 0,
      ));
      await tester.pumpAndSettle();

      expect(enabled(tester, 'Commencer la partie'), isFalse);
      expect(find.text('Déconnecté'), findsOneWidget);
    });

    testWidgets('un invité attend l\'hôte : pas de bouton de lancement', (tester) async {
      await inRoom(tester, seat: 1, names: ['Anna', 'Bob']);

      expect(find.text('En attente du lancement par l\'hôte…'), findsOneWidget);
      expect(find.text('Commencer la partie'), findsNothing);
      expect(find.byIcon(Icons.drag_handle), findsNothing, reason: 'seul l\'hôte règle l\'ordre');
    });

    testWidgets('l\'hôte voit une poignée par joueur', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna', 'Bob', 'Chloé']);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
      expect(find.text('Hôte'), findsOneWidget);
      expect(find.text('Joueurs (3/6)'), findsOneWidget);
    });

    testWidgets('le retour système quitte le salon', (tester) async {
      await inRoom(tester, seat: 0, names: ['Anna']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(transport.current.sent.any((m) => m.type == ClientMessageType.leave), isTrue);
    });
  });

  group('tirage au sort', () {
    const names = ['Anna', 'Bob'];
    const setup = GameSetup(playerNames: names);

    List<GameAction> journal() =>
        journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);

    List<GameAction> start(List<GameAction> full) =>
        full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);

    /// Le serveur d'avant le signal de départ : tout le monde a « Jouer ».
    const v1Server = [keepSelectionFeature, emotesFeature];

    Future<void> gameStarted(WidgetTester tester, List<GameAction> actions,
        {int seat = 0, List<String> features = v1Server}) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', names[seat]);
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: seat, features: features));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: actions));
      await tester.pump(const Duration(milliseconds: 20));
    }

    testWidgets('raconte le tirage puis mène à la partie', (tester) async {
      await gameStarted(tester, start(journal()));
      await pump(tester, const OnlineDiceOffScreen());

      // Les dés apparaissent, puis le résultat, puis le bouton.
      await tester.pump(OnlineDiceOffScreen.firstRollDelay + const Duration(milliseconds: 50));
      for (var i = 0; i < 6 && find.text('Jouer').evaluate().isEmpty; i++) {
        await tester.pump(OnlineDiceOffScreen.roundDelay + const Duration(milliseconds: 50));
      }
      expect(find.text('Jouer'), findsOneWidget);
      expect(find.textContaining('commence la partie'), findsOneWidget);

      await tester.tap(find.text('Jouer'));
      // Les dés de la partie s'animent sans fin : pas de pumpAndSettle. Une
      // image pour poser la route, une autre pour finir sa transition.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GameScreen), findsOneWidget);
    });

    testWidgets('un tap va droit au résultat', (tester) async {
      await gameStarted(tester, start(journal()));
      await pump(tester, const OnlineDiceOffScreen());

      await tester.tapAt(const Offset(20, 300));
      await tester.pump();
      expect(find.text('Jouer'), findsOneWidget);
    });

    group('avec le signal de départ', () {
      int starterOf(List<GameAction> actions) => replayGame(setup, 0, actions).playOrder!.first;

      testWidgets('le premier joueur a « Jouer » : il lance la partie pour tous', (tester) async {
        final actions = start(journal());
        await gameStarted(tester, actions, seat: starterOf(actions), features: serverFeatures);
        await pump(tester, const OnlineDiceOffScreen());
        await tester.tapAt(const Offset(20, 300));
        await tester.pump();

        await tester.tap(find.text('Jouer'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(transport.current.sent.last.type, ClientMessageType.begin);
        expect(find.byType(GameScreen), findsOneWidget);
      });

      testWidgets('les autres attendent, bouton inactif, et entrent quand le serveur annonce le départ', (tester) async {
        final actions = start(journal());
        await gameStarted(tester, actions, seat: 1 - starterOf(actions), features: serverFeatures);
        await pump(tester, const OnlineDiceOffScreen());
        await tester.tapAt(const Offset(20, 300));
        await tester.pump();

        final button = find.widgetWithText(FilledButton, 'En attente du début de la partie');
        expect(button, findsOneWidget);
        expect(tester.widget<FilledButton>(button).onPressed, isNull);

        transport.current.serverSends(ServerMessage.room(
          code: 'ABCDE',
          phase: RoomPhase.playing,
          seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
          hostSeat: 0,
          begun: true,
        ));
        await tester.pump(const Duration(milliseconds: 20));
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byType(GameScreen), findsOneWidget);
      });
    });

    testWidgets('une partie déjà entamée saute le tirage', (tester) async {
      final full = journal();
      final rollIndex = full.indexWhere((a) => a.type == GameActionType.roll);
      await gameStarted(tester, full.sublist(0, rollIndex + 2));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnlineDiceOffScreen(),
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameScreen), findsOneWidget);
    });
  });

  group('sélection de 5 de l\'autre joueur', () {
    const names = ['Anna', 'Bob'];
    const setup = GameSetup(playerNames: names);

    /// Un journal arrêté sur un lancer où garder plus ou moins de 5 est un vrai
    /// choix ; le siège qui a la main ; le nombre de 5 écartés par défaut et un
    /// autre nombre possible.
    ({List<GameAction> journal, int current, TurnState turn, int alternative}) atFivesChoice() {
      for (var seed = 1; seed < 100; seed++) {
        final full = journalWithFaces(setup, seed, playScriptedGame(setup, seed).actions);
        for (var end = 1; end <= full.length; end++) {
          if (full[end - 1].type != GameActionType.roll) continue;
          final replay = replayGame(setup, 0, full.sublist(0, end));
          final engine = replay.engine!;
          final turn = engine.activeTurn;
          final analysis = turn?.pendingRoll;
          if (turn == null || analysis == null || turn.busted) continue;
          final total = engine.currentPlayer.totalScore;
          final max = maxKeepableFives(turn, analysis, currentTotal: total);
          final min = minKeepableFives(analysis);
          if (max <= min) continue;
          // Un autre nombre de 5 que celui choisi par défaut, et qui change le score.
          final byDefault = defaultKeepCount(turn, analysis, currentTotal: total);
          final keep = byDefault == min ? max : min;
          return (
            journal: full.sublist(0, end),
            current: replay.playOrder![engine.currentPlayerIndex],
            turn: turn,
            alternative: analysis.declinableFives!.diceCount - keep,
          );
        }
      }
      throw StateError('aucun choix de 5 trouvé');
    }

    /// Le score de la main affiché pour [declineFivesCount] 5 écartés.
    int handScore(TurnState turn, int declineFivesCount) {
      final analysis = turn.pendingRoll!;
      final fives = analysis.declinableFives!;
      final keep = fives.diceCount - declineFivesCount;
      return turn.bankedScore +
          analysis.mandatoryGroups.fold<int>(0, (sum, g) => sum + g.points) +
          keep * (fives.points ~/ fives.diceCount);
    }

    Finder showsHandScore(int score) => find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('$score (>'),
        );

    Future<void> joined(WidgetTester tester, int seat, List<GameAction> journal) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', names[seat]);
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: seat));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: journal));
      await tester.pump(const Duration(milliseconds: 20));
    }

    /// L'écran de jeu, les dés immobilisés (ils s'animent sans fin ensuite :
    /// pas de pumpAndSettle).
    Future<void> openGame(WidgetTester tester) async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ));
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('le score de la main suit, en direct, la sélection de celui qui a la main', (tester) async {
      final choice = atFivesChoice();
      await joined(tester, 1 - choice.current, choice.journal);
      await openGame(tester);
      final analysis = choice.turn.pendingRoll!;
      final byDefault = defaultKeepCount(choice.turn, analysis, currentTotal: container.read(gameProvider)!.currentPlayer.totalScore);
      final defaultScore = handScore(choice.turn, analysis.declinableFives!.diceCount - byDefault);
      expect(showsHandScore(defaultScore), findsWidgets,
          reason: 'le lancer en attente compte déjà dans la main, sans attendre le coup suivant');
      expect(handScore(choice.turn, choice.alternative), isNot(defaultScore));

      transport.current.serverSends(ServerMessage.selection(seq: choice.journal.length, declineFivesCount: choice.alternative));
      await tester.pump(const Duration(milliseconds: 50));

      expect(showsHandScore(handScore(choice.turn, choice.alternative)), findsWidgets);
    });

    testWidgets('une sélection reçue avant que l\'écran de jeu ne s\'ouvre y est montrée', (tester) async {
      final choice = atFivesChoice();
      await joined(tester, 1 - choice.current, choice.journal);
      transport.current.serverSends(ServerMessage.selection(seq: choice.journal.length, declineFivesCount: choice.alternative));
      await tester.pump(const Duration(milliseconds: 20));

      await openGame(tester);

      expect(showsHandScore(handScore(choice.turn, choice.alternative)), findsWidgets);
    });

    testWidgets('à mon tour, changer le nombre de 5 envoie ma sélection', (tester) async {
      final choice = atFivesChoice();
      await joined(tester, choice.current, choice.journal);
      await openGame(tester);
      final keep = choice.turn.pendingRoll!.declinableFives!.diceCount - choice.alternative;

      tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).onChanged!(keep);
      await tester.pump(const Duration(milliseconds: 50));

      final sent = transport.current.sent.where((m) => m.type == ClientMessageType.select).toList();
      expect(sent.last.params['declineFivesCount'], choice.alternative);
      expect(showsHandScore(handScore(choice.turn, choice.alternative)), findsWidgets);
    });
  });

  group('émotions', () {
    const names = ['Anna', 'Bob'];
    const setup = GameSetup(playerNames: names);

    /// Le début d'une partie où le tirage au sort a inversé les sièges (Bob, au
    /// siège 1, joue en premier) : une bulle mal rattachée irait sur la
    /// mauvaise ligne.
    List<GameAction> swappedStart() {
      for (var seed = 1; seed < 100; seed++) {
        final full = journalWithFaces(setup, seed, playScriptedGame(setup, seed).actions);
        final start = full.sublist(0, full.indexWhere((a) => a.type == GameActionType.startTurn) + 1);
        if (replayGame(setup, 0, start).playOrder!.first == 1) return start;
      }
      throw StateError('aucun tirage qui inverse les sièges');
    }

    Future<void> joined(WidgetTester tester, {List<String> features = serverFeatures}) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', 'Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0, features: features));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: swappedStart()));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
    }

    Finder emoteButton(String name) => find.bySemanticsLabel(name);

    /// Le blason du joueur [name] dans la liste des joueurs.
    Finder avatarOf(String name) => find.byWidgetPredicate((w) => w is PlayerAvatarWidget && w.name == name).first;

    testWidgets('une phrase longue passe à la ligne au lieu d\'être tronquée', (tester) async {
      await joined(tester);

      transport.current.serverSends(ServerMessage.emote(seat: 0, emote: Emote.mocking, phrase: 'neverTakeA1000'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300)); // la bulle s'ouvre à la frame suivante

      final text = tester.widget<Text>(find.descendant(of: find.byType(SpeechBubble), matching: find.byType(Text)));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.getSize(find.byType(SpeechBubble)).width, lessThanOrEqualTo(240));
    });

    testWidgets('en ligne : quatre boutons d\'émotion, et l\'historique dans la barre du bas', (tester) async {
      await joined(tester);

      for (final name in ['Songeur', 'Mort de rire', 'Dévasté', 'Câlin']) {
        expect(emoteButton(name), findsOneWidget, reason: name);
      }
      expect(find.byKey(const ValueKey('history-bar')), findsOneWidget);
      expect(find.text('🤣'), findsOneWidget);
    });

    testWidgets('un serveur qui ne relaie pas les émotions : pas de boutons, l\'historique reste dans sa barre', (tester) async {
      await joined(tester, features: const [keepSelectionFeature]);

      expect(emoteButton('Mort de rire'), findsNothing);
      expect(find.byKey(const ValueKey('history-bar')), findsOneWidget);
    });

    testWidgets('un tap envoie l\'émoji ; les boutons restent grisés 3 secondes', (tester) async {
      await joined(tester);

      await tester.ensureVisible(emoteButton('Mort de rire'));
      await tester.tap(emoteButton('Mort de rire'));
      await tester.pump();
      final sent = transport.current.sent.where((m) => m.type == ClientMessageType.emote).toList();
      expect((sent.single.params['emote'], sent.single.params.containsKey('phrase')), ('mocking', false));

      await tester.tap(emoteButton('Câlin'), warnIfMissed: false);
      await tester.pump();
      expect(transport.current.sent.where((m) => m.type == ClientMessageType.emote), hasLength(1), reason: 'encore grisés');

      await tester.pump(emoteCooldown);
      await tester.tap(emoteButton('Câlin'));
      await tester.pump();
      expect(transport.current.sent.where((m) => m.type == ClientMessageType.emote), hasLength(2));
    });

    testWidgets('un appui long ouvre les phrases de l\'émotion ; en choisir une l\'envoie à la place de l\'émoji', (tester) async {
      await joined(tester);

      await tester.ensureVisible(emoteButton('Mort de rire'));
      await tester.longPress(emoteButton('Mort de rire'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Cinq qui colle !'), findsOneWidget);
      expect(find.text('Main pleine, main vaine !'), findsOneWidget);
      expect(find.text('On ne reprend jamais sur un 1000 !'), findsOneWidget);
      expect(find.text('La gourmandise est un vilain défaut !'), findsOneWidget);

      await tester.tap(find.text('Main pleine, main vaine !'));
      await tester.pump(const Duration(milliseconds: 400));

      final sent = transport.current.sent.where((m) => m.type == ClientMessageType.emote).single;
      expect((sent.params['emote'], sent.params['phrase']), ('mocking', 'fullHandEmptyHand'));
    });

    testWidgets('une phrase retirée du menu n\'y est plus proposée, mais s\'affiche encore quand on la reçoit', (tester) async {
      await joined(tester);

      await tester.ensureVisible(emoteButton('Câlin'));
      await tester.longPress(emoteButton('Câlin'));
      await tester.pump(const Duration(milliseconds: 400));
      for (final phrase in ['Salut !', 'Bonne chance !', 'Merci', 'Désolé mais je dois partir']) {
        expect(find.text(phrase), findsOneWidget, reason: phrase);
      }
      expect(find.text('Yes !'), findsNothing);
      await tester.tapAt(Offset.zero); // referme le menu
      await tester.pump(const Duration(milliseconds: 400));

      transport.current.serverSends(ServerMessage.emote(seat: 1, emote: Emote.joyful, phrase: 'yes'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300)); // la bulle s'ouvre à la frame suivante
      expect(find.widgetWithText(SpeechBubble, 'Yes !'), findsOneWidget);
    });

    testWidgets('une émotion reçue s\'affiche en bulle sur la ligne de qui l\'envoie, puis s\'efface et reste dans l\'Historique',
        (tester) async {
      await joined(tester);

      // Bob est au siège 1, mais en tête de la liste (il joue en premier).
      transport.current.serverSends(ServerMessage.emote(seat: 1, emote: Emote.mocking, phrase: 'stickyFive'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300)); // la bulle s'ouvre à la frame suivante

      final bubble = find.widgetWithText(SpeechBubble, 'Cinq qui colle !');
      expect(bubble, findsOneWidget);
      // La bulle part du blason de Bob : collée à son bord droit, centrée sur lui.
      final bob = tester.getRect(avatarOf('Bob'));
      final rect = tester.getRect(bubble);
      expect(rect.left, closeTo(bob.right, 4), reason: 'la pointe touche le blason de Bob');
      expect(rect.center.dy, closeTo(bob.center.dy, 1), reason: 'à la hauteur de Bob, pas d\'Anna');

      await tester.pump(GameScreen.bubbleDuration);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SpeechBubble), findsNothing, reason: 'la bulle s\'efface');

      await tester.tap(find.byKey(const ValueKey('history-bar')));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(BottomSheet), findsOneWidget, reason: 'l\'historique se déroule');
      expect(inHistory(find.textContaining('Cinq qui colle !', findRichText: true)), findsOneWidget,
          reason: 'elle reste dans l\'historique');
    });
  });

  group('fin de partie en ligne', () {
    const names = ['Anna', 'Bob'];
    const setup = GameSetup(playerNames: names);
    const seats = [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)];

    void room(RoomPhase phase, {bool begun = true}) => transport.current.serverSends(
          ServerMessage.room(code: 'ABCDE', phase: phase, seats: seats, hostSeat: 0, begun: begun),
        );

    /// Une partie en ligne finie, à l'écran de fin, sur l'accueil.
    Future<void> finished(WidgetTester tester) async {
      await container.read(onlineSessionProvider.notifier).join('abcde', 'Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      room(RoomPhase.playing);
      final full = journalWithFaces(setup, 5, playScriptedGame(setup, 5).actions);
      transport.current.serverSends(ServerMessage.snapshot(names: names, actions: full));
      room(RoomPhase.over);
      await tester.pump(const Duration(milliseconds: 20));
      final engine = container.read(gameProvider)!;
      expect(engine.gameOver, isTrue);
      await pump(
        tester,
        Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => GameOverScreen(players: engine.players, winnerIndex: engine.winnerIndex!),
                )),
                child: const Text('accueil'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('accueil'));
      await tester.pumpAndSettle();
    }

    testWidgets('« Rejouer » propose la revanche ; la barre d\'émotions est là', (tester) async {
      await finished(tester);
      expect(find.bySemanticsLabel('Fâché'), findsOneWidget, reason: 'seconde série : le serveur la connaît');

      await tester.ensureVisible(find.byKey(const ValueKey('rematch-propose')));
      await tester.tap(find.byKey(const ValueKey('rematch-propose')));
      await tester.pump();
      final sent = transport.current.sent.last;
      expect((sent.type, sent.rematchAnswer), (ClientMessageType.rematch, RematchAnswer.propose));
    });

    testWidgets('la revanche d\'un autre : l\'accepter, puis la nouvelle partie s\'ouvre', (tester) async {
      await finished(tester);
      transport.current.serverSends(ServerMessage.rematch(status: RematchStatus.pending, proposerSeat: 1, remainingMs: 45000, answers: const {1: true}));
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Bob propose une revanche'), findsOneWidget);
      expect(find.text('45 s'), findsOneWidget);

      await tester.ensureVisible(find.text('Accepter'));
      await tester.tap(find.text('Accepter'));
      await tester.pump();
      expect(transport.current.sent.last.rematchAnswer, RematchAnswer.accept);

      // Le serveur lance la revanche : nouveau siège, journal sans tirage.
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 1));
      transport.current.serverSends(ServerMessage.snapshot(
        names: const ['Bob', 'Anna'],
        actions: [GameAction.presetOrder(const [0, 1]), GameAction.startTurn(useFullHand: false)],
      ));
      room(RoomPhase.playing);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GameScreen), findsOneWidget);
      expect(find.byType(GameOverScreen), findsNothing);
      expect(container.read(gameProvider)!.gameOver, isFalse);
    });

    testWidgets('refuser la revanche ramène à l\'accueil, hors du salon', (tester) async {
      await finished(tester);
      transport.current.serverSends(ServerMessage.rematch(status: RematchStatus.pending, proposerSeat: 1, remainingMs: 45000));
      await tester.pump(const Duration(milliseconds: 20));

      await tester.ensureVisible(find.text('Refuser'));
      await tester.tap(find.text('Refuser'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(find.text('accueil'), findsOneWidget);
      expect(transport.channels.first.sent.any((m) => m.type == ClientMessageType.rematch && m.rematchAnswer == RematchAnswer.refuse), isTrue);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
    });

    testWidgets('une revanche abandonnée ramène à l\'accueil en le disant', (tester) async {
      await finished(tester);
      transport.current.serverSends(ServerMessage.rematch(status: RematchStatus.cancelled));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      expect(find.text('accueil'), findsOneWidget);
      expect(find.text('Pas de revanche : il faut au moins deux joueurs.'), findsOneWidget);
    });
  });

  group('quitter une partie en ligne en cours', () {
    testWidgets('le retour demande confirmation ; confirmé, on quitte le salon et un bot prend la place', (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: _startedJournal()));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
        begun: true,
      ));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('un bot jouera à votre place'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(transport.current.sent.any((m) => m.type == ClientMessageType.leave), isFalse, reason: 'annulé : on reste');

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(FilledButton, 'Quitter'));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(transport.channels.first.sent.any((m) => m.type == ClientMessageType.leave), isTrue);
      expect(container.read(onlineSessionProvider).inRoom, isFalse);
    });

    testWidgets('un joueur remplacé par un bot : icône sur sa ligne, et l\'historique le dit', (tester) async {
      await container.read(onlineSessionProvider.notifier).create('Anna');
      transport.current.serverSends(ServerMessage.joined(code: 'ABCDE', token: _token, seat: 0));
      transport.current.serverSends(ServerMessage.snapshot(names: const ['Anna', 'Bob'], actions: _startedJournal()));
      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true)],
        hostSeat: 0,
      ));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.smart_toy_outlined), findsNothing);

      transport.current.serverSends(ServerMessage.room(
        code: 'ABCDE',
        phase: RoomPhase.playing,
        seats: const [SeatInfo(name: 'Anna', connected: true), SeatInfo(name: 'Bob', connected: true, bot: true)],
        hostSeat: 0,
      ));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.textContaining('un bot joue à sa place'), findsOneWidget, reason: 'dernière entrée, dans la barre');
    });
  });
}
