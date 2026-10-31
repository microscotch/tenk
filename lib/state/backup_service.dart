import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/player_profile.dart';
import 'backup_archive.dart';
import 'game_save_store.dart';
import 'player_store.dart';

/// Ce que l'import fait des données déjà présentes sur le téléphone.
enum BackupImportMode {
  /// Ajoute les parties et les fiches qui manquent, sans rien supprimer ni
  /// toucher à ce qui existe (un même nom de fichier est la même partie, la même
  /// fiche : la version du téléphone est gardée). Les réglages du fichier
  /// remplacent les actuels.
  merge,

  /// Efface les données actuelles, puis installe celles du fichier : l'état est
  /// celui de l'export.
  replace,
}

class BackupRestoreResult {
  /// Parties (terminées et en pause) écrites sur le téléphone.
  final int games;

  /// Fiches joueurs écrites.
  final int profiles;

  /// Entrées du fichier ignorées parce qu'illisibles.
  final int skipped;

  const BackupRestoreResult({required this.games, required this.profiles, required this.skipped});
}

/// Le service de sauvegarde, derrière un fournisseur : les tests le surchargent
/// avec des dossiers temporaires.
final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(
    paused: ref.watch(gameSaveStoreProvider),
    finished: ref.watch(archivedGameSaveStoreProvider),
    players: ref.watch(playerStoreProvider),
  ),
);

/// Sauvegarde et restaure les données de l'utilisateur : parties terminées et en
/// pause, fiches joueurs, réglages (clefs `settings.*`).
///
/// **Ne sort jamais du téléphone ce qui n'est pas à l'utilisateur** : le jeton de
/// reconnexion d'une partie en ligne (`online.*`) n'est pas un réglage, et une
/// clef de réglage doit commencer par `settings.` pour entrer dans un fichier,
/// comme pour en sortir.
class BackupService {
  final GameSaveStore paused;
  final GameSaveStore finished;
  final PlayerStore players;
  final Future<SharedPreferences> Function() _prefs;

  BackupService({
    required this.paused,
    required this.finished,
    required this.players,
    Future<SharedPreferences> Function()? prefs,
  }) : _prefs = prefs ?? SharedPreferences.getInstance;

  static const _settingsPrefix = 'settings.';

  /// Le contenu d'une sauvegarde, tel qu'il est sur le téléphone maintenant.
  Future<BackupArchive> collect() async {
    final prefs = await _prefs();
    final settings = <String, Object>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_settingsPrefix)) continue;
      final value = prefs.get(key);
      if (value is bool || value is int || value is double || value is String) {
        settings[key] = value!;
      } else if (value is List) {
        settings[key] = value.cast<String>().toList();
      }
    }
    return BackupArchive(
      createdAt: DateTime.now(),
      settings: settings,
      players: await _readFiles(await players.directory(), _isPlayerFile, _validPlayer),
      paused: await _readFiles(await paused.directory(), _isGameFile, _validGame),
      finished: await _readFiles(await finished.directory(), _isGameFile, _validGame),
    );
  }

  /// Le fichier de sauvegarde, chiffré par [password] — le mot de passe de
  /// l'utilisateur, d'au moins [BackupEnvelope.minPasswordLength] caractères. Rien
  /// ne le garde : qui le perd perd la sauvegarde. [iterations] n'est à changer que
  /// par les tests.
  Future<Uint8List> export(String password, {int iterations = BackupEnvelope.defaultIterations}) async {
    if (password.length < BackupEnvelope.minPasswordLength) throw ArgumentError('Mot de passe trop court');
    return BackupEnvelope.seal(await collect(), password, iterations: iterations);
  }

  /// Vérifie que [bytes] est bien une sauvegarde lisible par cette version de
  /// l'app, **sans le mot de passe** : on peut le faire avant de le demander.
  /// Lève [BackupException].
  void check(Uint8List bytes) => BackupEnvelope.check(bytes);

  /// Ouvre [bytes] avec [password] : déchiffre et authentifie, sans toucher à rien
  /// sur le disque. Lève [BackupException] (dont [BackupFailure.wrongPassword]).
  Future<BackupArchive> open(Uint8List bytes, String password) => BackupEnvelope.open(bytes, password);

  /// Installe [archive] sur le téléphone selon [mode]. Tout est validé en
  /// mémoire avant la première écriture : un fichier de l'archive illisible est
  /// écarté et compté, il n'arrête pas la restauration.
  Future<BackupRestoreResult> restore(BackupArchive archive, BackupImportMode mode) async {
    final playerFiles = _filter(archive.players, _validPlayer);
    final pausedFiles = _filter(archive.paused, _validGame);
    final finishedFiles = _filter(archive.finished, _validGame);
    final skipped = (archive.players.length - playerFiles.length) +
        (archive.paused.length - pausedFiles.length) +
        (archive.finished.length - finishedFiles.length);

    switch (mode) {
      case BackupImportMode.merge:
        final profiles = await _merge(await players.directory(), playerFiles);
        final games =
            await _merge(await paused.directory(), pausedFiles) + await _merge(await finished.directory(), finishedFiles);
        await _writeSettings(archive.settings, clear: false);
        return BackupRestoreResult(games: games, profiles: profiles, skipped: skipped);
      case BackupImportMode.replace:
        await _replace(await players.directory(), playerFiles);
        await _replace(await paused.directory(), pausedFiles);
        await _replace(await finished.directory(), finishedFiles);
        await _writeSettings(archive.settings, clear: true);
        return BackupRestoreResult(
          games: pausedFiles.length + finishedFiles.length,
          profiles: playerFiles.length,
          skipped: skipped,
        );
    }
  }

  static bool _isGameFile(String name) => BackupArchive.gameFileName.hasMatch(name);
  static bool _isPlayerFile(String name) => BackupArchive.playerFileName.hasMatch(name);

  static bool _validGame(String content) {
    try {
      SavedGame.fromJson(jsonDecode(content) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _validPlayer(String content) {
    try {
      PlayerProfile.fromJson(jsonDecode(content) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Map<String, String> _filter(Map<String, String> files, bool Function(String) valid) =>
      {for (final e in files.entries) if (valid(e.value)) e.key: e.value};

  /// Les fichiers de [dir] dont le nom est accepté et le contenu lisible : un
  /// fichier corrompu n'entre pas dans une sauvegarde (le reste de l'app les
  /// ignore de la même façon).
  Future<Map<String, String>> _readFiles(
    Directory dir,
    bool Function(String name) acceptsName,
    bool Function(String content) valid,
  ) async {
    final files = <String, String>{};
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!acceptsName(name)) continue;
      try {
        final content = await entity.readAsString();
        if (valid(content)) files[name] = content;
      } catch (_) {}
    }
    return files;
  }

  Future<void> _writeAtomically(File target, String content) async {
    final tmp = File('${target.path}.tmp');
    await tmp.writeAsString(content);
    await tmp.rename(target.path);
  }

  /// Ajoute à [dir] les fichiers qui n'y sont pas. Rend combien.
  Future<int> _merge(Directory dir, Map<String, String> files) async {
    var added = 0;
    for (final e in files.entries) {
      final target = File('${dir.path}/${e.key}');
      if (await target.exists()) continue;
      await _writeAtomically(target, e.value);
      added++;
    }
    return added;
  }

  /// Remplace tout le contenu de [dir] par [files] : on écrit dans un dossier
  /// voisin, puis on échange les deux, pour qu'une erreur en route laisse
  /// l'ancien contenu en place.
  Future<void> _replace(Directory dir, Map<String, String> files) async {
    final fresh = Directory('${dir.path}.restore');
    final old = Directory('${dir.path}.previous');
    if (await fresh.exists()) await fresh.delete(recursive: true);
    if (await old.exists()) await old.delete(recursive: true);
    await fresh.create(recursive: true);
    for (final e in files.entries) {
      await File('${fresh.path}/${e.key}').writeAsString(e.value);
    }
    await dir.rename(old.path);
    try {
      await fresh.rename(dir.path);
    } catch (_) {
      await old.rename(dir.path);
      rethrow;
    }
    await old.delete(recursive: true);
  }

  Future<void> _writeSettings(Map<String, Object> settings, {required bool clear}) async {
    final prefs = await _prefs();
    if (clear) {
      for (final key in prefs.getKeys().where((k) => k.startsWith(_settingsPrefix)).toList()) {
        await prefs.remove(key);
      }
    }
    for (final e in settings.entries) {
      switch (e.value) {
        case bool v:
          await prefs.setBool(e.key, v);
        case int v:
          await prefs.setInt(e.key, v);
        case double v:
          await prefs.setDouble(e.key, v);
        case String v:
          await prefs.setString(e.key, v);
        case List<String> v:
          await prefs.setStringList(e.key, v);
      }
    }
  }
}
