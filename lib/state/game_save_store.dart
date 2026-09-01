import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../game/ai/ai_profiles.dart';
import '../game/game_recording.dart';
import '../game/game_setup.dart';

/// Le [GameSaveStore] partagé par l'app — surchargeable en test via
/// `ProviderContainer(overrides: [gameSaveStoreProvider.overrideWithValue(...)])`
/// pour pointer vers un dossier temporaire plutôt que le vrai dossier
/// documents de l'appareil.
final gameSaveStoreProvider = Provider<GameSaveStore>((ref) => GameSaveStore());

/// Les parties en pause, pour la liste de l'écran d'accueil. Se recharge
/// depuis le disque à chaque `ref.invalidate(pausedGamesProvider)` (voir
/// `SetupScreen`, rafraîchi au retour sur l'écran).
final pausedGamesProvider = FutureProvider<List<SavedGame>>((ref) {
  final store = ref.watch(gameSaveStoreProvider);
  return store.list();
});

/// Snapshot persistable d'une partie en cours : tout ce qu'il faut pour la
/// reconstruire à l'identique via `replayGame` (voir
/// `lib/game/game_recording.dart`), plus les métadonnées d'affichage (alias,
/// dates, durée cumulée).
class SavedGame {
  final int seed;
  final GameSetup setup;
  final String alias;
  final DateTime createdAt;

  /// Instant où le tirage au sort a été résolu et où la partie principale a
  /// réellement démarré (null tant que le journal d'actions n'en est pas
  /// encore là).
  final DateTime? enteredPlayAt;

  /// Somme des écarts entre actions consécutives, mise à jour après chaque
  /// transition (une longue pause réelle entre deux actions compte donc en
  /// entier — pas de détection de pause/veille).
  final int durationSeconds;

  final List<GameAction> actions;

  const SavedGame({
    required this.seed,
    required this.setup,
    required this.alias,
    required this.createdAt,
    this.enteredPlayAt,
    this.durationSeconds = 0,
    this.actions = const [],
  });

  SavedGame copyWith({DateTime? enteredPlayAt, int? durationSeconds, List<GameAction>? actions}) {
    return SavedGame(
      seed: seed,
      setup: setup,
      alias: alias,
      createdAt: createdAt,
      enteredPlayAt: enteredPlayAt ?? this.enteredPlayAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'seed': seed,
        'setup': {
          'playerNames': setup.playerNames,
          'aiPlayers': setup.aiPlayers.map((index, difficulty) => MapEntry(index.toString(), difficulty.name)),
          'autoPlayers': setup.autoPlayers.toList(),
        },
        'alias': alias,
        'createdAt': createdAt.toIso8601String(),
        'enteredPlayAt': enteredPlayAt?.toIso8601String(),
        'durationSeconds': durationSeconds,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  factory SavedGame.fromJson(Map<String, dynamic> json) {
    final setupJson = json['setup'] as Map<String, dynamic>;
    final enteredPlayAtRaw = json['enteredPlayAt'] as String?;
    return SavedGame(
      seed: json['seed'] as int,
      setup: GameSetup(
        playerNames: List<String>.from(setupJson['playerNames'] as List),
        aiPlayers: (setupJson['aiPlayers'] as Map).map(
          (index, difficultyName) =>
              MapEntry(int.parse(index as String), AiDifficulty.values.byName(difficultyName as String)),
        ),
        autoPlayers: Set<int>.from(setupJson['autoPlayers'] as List),
      ),
      alias: json['alias'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      enteredPlayAt: enteredPlayAtRaw != null ? DateTime.parse(enteredPlayAtRaw) : null,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      actions: (json['actions'] as List).map((a) => GameAction.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }
}

/// Lit/écrit les parties en pause sur disque, un fichier JSON par partie
/// (`game-<seed>.run`) dans un dossier `in-progress`. La racine est
/// surchargeable (voir [rootDirectory]) pour pointer les tests vers un
/// dossier temporaire plutôt que le vrai dossier documents de l'app.
class GameSaveStore {
  final Future<Directory> Function() rootDirectory;

  GameSaveStore({Future<Directory> Function()? rootDirectory}) : rootDirectory = rootDirectory ?? _defaultRoot;

  static Future<Directory> _defaultRoot() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/in-progress');
  }

  Future<Directory> _ensureDir() async {
    final dir = await rootDirectory();
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _fileFor(Directory dir, int seed) => File('${dir.path}/game-$seed.run');

  /// Vrai si une partie avec cette seed existe déjà (pour éviter une
  /// collision de nom de fichier lors de la génération d'une nouvelle seed).
  Future<bool> exists(int seed) async {
    final dir = await _ensureDir();
    return _fileFor(dir, seed).exists();
  }

  /// Liste les parties en pause, triées par date de dernière modification du
  /// fichier décroissante (la plus récemment jouée en premier).
  Future<List<SavedGame>> list() async {
    final dir = await _ensureDir();
    final entries = await dir.list().toList();
    final files = entries.whereType<File>().where((f) => f.path.endsWith('.run')).toList();

    final withStat = await Future.wait(files.map((f) async => (file: f, modified: (await f.stat()).modified)));
    withStat.sort((a, b) => b.modified.compareTo(a.modified));

    final games = <SavedGame>[];
    for (final entry in withStat) {
      try {
        final content = await entry.file.readAsString();
        games.add(SavedGame.fromJson(jsonDecode(content) as Map<String, dynamic>));
      } catch (_) {
        // Fichier corrompu/partiellement écrit : ignoré plutôt que de faire
        // planter tout l'écran d'accueil pour une seule sauvegarde invalide.
      }
    }
    return games;
  }

  Future<SavedGame?> read(int seed) async {
    final dir = await _ensureDir();
    final file = _fileFor(dir, seed);
    if (!await file.exists()) return null;
    return SavedGame.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
  }

  /// Écriture atomique (fichier temporaire puis renommage) pour ne jamais
  /// laisser un `.run` à moitié écrit si l'app est tuée en cours d'écriture.
  Future<void> write(SavedGame game) async {
    final dir = await _ensureDir();
    final target = _fileFor(dir, game.seed);
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(jsonEncode(game.toJson()));
    await tmp.rename(target.path);
  }

  Future<void> delete(int seed) async {
    final dir = await _ensureDir();
    final file = _fileFor(dir, seed);
    if (await file.exists()) await file.delete();
  }
}
