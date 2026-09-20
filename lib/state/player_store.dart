import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../game/player_profile.dart';

/// Le [PlayerStore] partagé par l'app — surchargeable en test via
/// `ProviderContainer(overrides: [playerStoreProvider.overrideWithValue(...)])`
/// pour pointer vers un dossier temporaire plutôt que le vrai dossier
/// documents de l'appareil.
final playerStoreProvider = Provider<PlayerStore>((ref) => PlayerStore());

/// Les fiches joueurs, triées par nom. Se recharge depuis le disque à chaque
/// `ref.invalidate(playersProvider)`, au retour sur un écran qui a pu les
/// modifier — même patron que `pausedGamesProvider`.
final playersProvider = FutureProvider<List<PlayerProfile>>((ref) {
  return ref.watch(playerStoreProvider).list();
});

/// Lit/écrit la base des joueurs humains, un fichier JSON par fiche
/// (`player-<id>.json`) dans un dossier `players`. Calqué sur `GameSaveStore`
/// (voir `game_save_store.dart`) : mêmes écritures atomiques, même tolérance
/// aux fichiers illisibles, même racine surchargeable pour les tests.
class PlayerStore {
  final Future<Directory> Function() rootDirectory;

  PlayerStore({Future<Directory> Function()? rootDirectory}) : rootDirectory = rootDirectory ?? _defaultRoot;

  static Future<Directory> _defaultRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/players');
  }

  Future<Directory> _ensureDir() async {
    final dir = await rootDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _fileFor(Directory dir, String id) => File('${dir.path}/player-$id.json');

  Future<bool> exists(String id) async {
    final dir = await _ensureDir();
    return _fileFor(dir, id).exists();
  }

  /// Liste les fiches, triées par nom — une liste de personnes se lit dans
  /// l'ordre alphabétique, contrairement à une liste de parties qu'on trie par
  /// date de dernière touche.
  Future<List<PlayerProfile>> list() async {
    final dir = await _ensureDir();
    final entries = await dir.list().toList();
    final files = entries.whereType<File>().where((f) => f.path.endsWith('.json')).toList();

    final players = <PlayerProfile>[];
    for (final file in files) {
      try {
        players.add(PlayerProfile.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>));
      } catch (_) {
        // Fichier corrompu ou partiellement écrit : ignoré plutôt que de faire
        // échouer l'écran entier pour une seule fiche invalide.
      }
    }
    players.sort((a, b) => normalizeName(a.name).compareTo(normalizeName(b.name)));
    return players;
  }

  Future<PlayerProfile?> read(String id) async {
    final dir = await _ensureDir();
    final file = _fileFor(dir, id);
    if (!await file.exists()) return null;
    return PlayerProfile.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
  }

  /// Écriture atomique (fichier temporaire puis renommage) pour ne jamais
  /// laisser une fiche à moitié écrite si l'app est tuée en cours d'écriture.
  Future<void> write(PlayerProfile player) async {
    final dir = await _ensureDir();
    final target = _fileFor(dir, player.id);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(player.toJson()));
    await tmp.rename(target.path);
  }

  Future<void> delete(String id) async {
    final dir = await _ensureDir();
    final file = _fileFor(dir, id);
    if (await file.exists()) await file.delete();
  }

  /// Vrai si [name] est déjà porté par une autre fiche, aux accents et à la
  /// casse près (voir [normalizeName]). [exceptId] permet de valider le
  /// renommage d'une fiche sans qu'elle se heurte à elle-même.
  ///
  /// Un magasin fichier-par-fiche ne peut pas rendre cette vérification
  /// atomique avec l'écriture qui suit : deux créations simultanées du même
  /// nom passeraient toutes deux. C'est une course réelle mais sans portée
  /// ici, l'app étant mono-utilisateur et locale.
  Future<bool> nameTaken(String name, {String? exceptId}) async {
    final normalized = normalizeName(name);
    final players = await list();
    return players.any((p) => p.id != exceptId && normalizeName(p.name) == normalized);
  }
}
