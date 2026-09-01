import 'dart:io';

import 'package:le10000/state/game_save_store.dart';

/// Implémentation en mémoire de [GameSaveStore], sans aucune E/S disque
/// réelle : `flutter_test` (`testWidgets`) ne résout pas de façon fiable de
/// vraies opérations `dart:io` pendant les cycles de pompage — un souci
/// d'environnement de test, pas du code applicatif (déjà couvert contre de
/// vrais fichiers dans `test/state/game_save_store_test.dart`, hors
/// `testWidgets`). N'implémente que l'interface publique de [GameSaveStore].
class FakeGameSaveStore implements GameSaveStore {
  final Map<int, SavedGame> _games = {};

  @override
  Future<Directory> Function() get rootDirectory => () => throw UnimplementedError();

  @override
  Future<bool> exists(int seed) async => _games.containsKey(seed);

  @override
  Future<List<SavedGame>> list() async => _games.values.toList();

  @override
  Future<SavedGame?> read(int seed) async => _games[seed];

  @override
  Future<void> write(SavedGame game) async => _games[game.seed] = game;

  @override
  Future<void> delete(int seed) async => _games.remove(seed);
}
