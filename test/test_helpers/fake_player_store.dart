import 'dart:io';

import 'package:le10000/game/player_profile.dart';
import 'package:le10000/state/player_store.dart';

/// [PlayerStore] en mémoire pour les tests de widgets.
///
/// Même raison d'être que [FakeGameSaveStore] : les cycles de pump de
/// `testWidgets` ne résolvent pas fiablement les opérations `dart:io` réelles.
/// Les tests du vrai magasin sur fichiers vivent à part, dans
/// `test/state/player_store_test.dart`.
class FakePlayerStore implements PlayerStore {
  final Map<String, PlayerProfile> _players = {};

  @override
  Future<Directory> Function() get rootDirectory => throw UnimplementedError();

  @override
  Future<bool> exists(String id) async => _players.containsKey(id);

  @override
  Future<List<PlayerProfile>> list() async {
    final players = _players.values.toList();
    players.sort((a, b) => normalizeName(a.name).compareTo(normalizeName(b.name)));
    return players;
  }

  @override
  Future<PlayerProfile?> read(String id) async => _players[id];

  @override
  Future<void> write(PlayerProfile player) async => _players[player.id] = player;

  @override
  Future<void> delete(String id) async => _players.remove(id);

  @override
  Future<bool> nameTaken(String name, {String? exceptId}) async {
    final normalized = normalizeName(name);
    return _players.values.any((p) => p.id != exceptId && normalizeName(p.name) == normalized);
  }
}
