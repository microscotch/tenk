import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Pourquoi un fichier de sauvegarde n'a pas pu être ouvert.
enum BackupFailure {
  /// Pas un fichier de sauvegarde TenK (mauvais en-tête, trop court).
  notABackup,

  /// Écrit par une version de l'app plus récente que celle-ci.
  unsupportedVersion,

  /// Le mot de passe ne déchiffre pas le fichier. Indiscernable d'un fichier
  /// modifié ou tronqué : le chiffrement authentifié ne dit pas lequel des deux.
  wrongPassword,

  /// Déchiffré, mais le contenu n'est pas celui que l'app écrit.
  corrupted,
}

class BackupException implements Exception {
  final BackupFailure failure;
  const BackupException(this.failure);

  @override
  String toString() => 'BackupException($failure)';
}

/// Le contenu d'une sauvegarde : les réglages et les fichiers de l'app, sous la
/// forme où ils sont sur le disque (`game-<seed>.run`, `player-<id>.json`) — on ne
/// les réinterprète pas, on les emporte tels quels.
///
/// Rien de ce qui touche à une connexion n'y entre : seules les clefs de
/// réglage `settings.*` sont prises (voir `BackupService`), jamais le jeton de
/// reconnexion d'une partie en ligne.
class BackupArchive {
  /// Réglages : clef `SharedPreferences` → bool, int, double, String ou
  /// `List<String>`.
  final Map<String, Object> settings;

  /// Fiches joueurs : nom de fichier → contenu.
  final Map<String, String> players;

  /// Parties en pause : nom de fichier → contenu.
  final Map<String, String> paused;

  /// Parties terminées (archivées) : nom de fichier → contenu.
  final Map<String, String> finished;

  final DateTime createdAt;

  const BackupArchive({
    this.settings = const {},
    this.players = const {},
    this.paused = const {},
    this.finished = const {},
    required this.createdAt,
  });

  /// La version du format JSON, indépendante de celle de l'enveloppe chiffrée.
  static const formatVersion = 1;

  /// Un nom de fichier n'est accepté que sous la forme exacte que l'app écrit : il
  /// est recréé tel quel dans un dossier de l'app, un nom comme `../x` en
  /// sortirait.
  static final playerFileName = RegExp(r'^player-[A-Za-z0-9_-]+\.json$');
  static final gameFileName = RegExp(r'^game-\d+\.run$');

  Map<String, Object?> toJson() => {
        'format': formatVersion,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'settings': {for (final e in settings.entries) e.key: _encodeSetting(e.value)},
        'players': players,
        'paused': paused,
        'finished': finished,
      };

  factory BackupArchive.fromJson(Map<String, Object?> json) {
    try {
      if ((json['format'] as int) > formatVersion) throw const BackupException(BackupFailure.unsupportedVersion);
      Map<String, String> files(String key, RegExp name) {
        final raw = (json[key] as Map).cast<String, Object?>();
        // Un nom qui n'a pas la forme de ceux de l'app est écarté, pas corrigé.
        return {for (final e in raw.entries) if (name.hasMatch(e.key)) e.key: e.value as String};
      }

      return BackupArchive(
        createdAt: DateTime.parse(json['createdAt'] as String),
        settings: {
          for (final e in (json['settings'] as Map).cast<String, Object?>().entries)
            if (e.key.startsWith('settings.')) e.key: _decodeSetting(e.value as Map),
        },
        players: files('players', playerFileName),
        paused: files('paused', gameFileName),
        finished: files('finished', gameFileName),
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupFailure.corrupted);
    }
  }

  static Map<String, Object?> _encodeSetting(Object value) => switch (value) {
        bool v => {'t': 'bool', 'v': v},
        int v => {'t': 'int', 'v': v},
        double v => {'t': 'double', 'v': v},
        String v => {'t': 'string', 'v': v},
        List<String> v => {'t': 'list', 'v': v},
        _ => throw ArgumentError('Réglage de type inattendu : ${value.runtimeType}'),
      };

  static Object _decodeSetting(Map raw) => switch (raw['t']) {
        'bool' => raw['v'] as bool,
        'int' => raw['v'] as int,
        'double' => (raw['v'] as num).toDouble(),
        'string' => raw['v'] as String,
        'list' => (raw['v'] as List).cast<String>().toList(),
        _ => throw const BackupException(BackupFailure.corrupted),
      };
}

/// L'enveloppe chiffrée d'une [BackupArchive], protégée par un mot de passe :
/// `TENKBAK`, la version (1 octet), le nombre d'itérations de la dérivation
/// (4 octets), le sel (16 octets), le nonce (12 octets), puis le JSON compressé
/// chiffré en AES-256-GCM et son étiquette (16 octets). L'en-tête est authentifié
/// avec le reste : l'étiquette échoue si on y touche.
///
/// La clef vient du mot de passe par PBKDF2-HMAC-SHA256 ([defaultIterations]
/// itérations, sel aléatoire propre à chaque fichier). Les itérations sont écrites
/// dans le fichier : on peut les augmenter un jour sans casser les anciens, et les
/// tests en prennent peu.
class BackupEnvelope {
  static final _magic = utf8.encode('TENKBAK');
  static const version = 1;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _tagLength = 16;
  static const _headerLength = 7 + 1 + 4 + _saltLength;

  /// Recommandation OWASP (2023) pour PBKDF2-HMAC-SHA256.
  static const defaultIterations = 600000;

  /// Bornes acceptées à la lecture : un fichier est une donnée extérieure, un
  /// nombre d'itérations démesuré gèlerait l'app pendant des heures.
  static const _maxIterations = 5000000;

  /// Longueur minimale d'un mot de passe d'export.
  static const minPasswordLength = 8;

  static final _cipher = AesGcm.with256bits();

  static Uint8List _random(int length) {
    final random = Random.secure();
    return Uint8List.fromList([for (var i = 0; i < length; i++) random.nextInt(256)]);
  }

  /// La clef AES-256 de [password]. Calculée dans un isolat : plusieurs
  /// secondes de calcul sur un téléphone, qui ne doivent pas figer l'interface.
  static Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) async {
    final bytes = await Isolate.run(() async {
      final key = await Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      ).deriveKeyFromPassword(password: password, nonce: salt);
      return key.extractBytes();
    });
    return SecretKey(bytes);
  }

  static int _iterationsOf(Uint8List bytes) =>
      (bytes[8] << 24) | (bytes[9] << 16) | (bytes[10] << 8) | bytes[11];

  /// Vérifie que [bytes] a la forme d'une sauvegarde que cette version sait lire,
  /// sans mot de passe. Lève [BackupFailure.notABackup] ou
  /// [BackupFailure.unsupportedVersion].
  static void check(Uint8List bytes) {
    if (bytes.length < _headerLength + _nonceLength + _tagLength) throw const BackupException(BackupFailure.notABackup);
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) throw const BackupException(BackupFailure.notABackup);
    }
    if (bytes[_magic.length] > version) throw const BackupException(BackupFailure.unsupportedVersion);
    final iterations = _iterationsOf(bytes);
    if (iterations < 1 || iterations > _maxIterations) throw const BackupException(BackupFailure.notABackup);
  }

  static Future<Uint8List> seal(
    BackupArchive archive,
    String password, {
    int iterations = defaultIterations,
  }) async {
    final salt = _random(_saltLength);
    final header = Uint8List.fromList([
      ..._magic,
      version,
      (iterations >> 24) & 0xff,
      (iterations >> 16) & 0xff,
      (iterations >> 8) & 0xff,
      iterations & 0xff,
      ...salt,
    ]);
    final clear = gzip.encode(utf8.encode(jsonEncode(archive.toJson())));
    final box = await _cipher.encrypt(
      clear,
      secretKey: await _deriveKey(password, salt, iterations),
      nonce: _random(_nonceLength),
      aad: header,
    );
    return Uint8List.fromList([...header, ...box.nonce, ...box.cipherText, ...box.mac.bytes]);
  }

  static Future<BackupArchive> open(Uint8List bytes, String password) async {
    check(bytes);
    final header = Uint8List.sublistView(bytes, 0, _headerLength);
    final salt = bytes.sublist(_headerLength - _saltLength, _headerLength);
    final nonce = bytes.sublist(_headerLength, _headerLength + _nonceLength);
    final cipherText = bytes.sublist(_headerLength + _nonceLength, bytes.length - _tagLength);
    final tag = bytes.sublist(bytes.length - _tagLength);
    final List<int> clear;
    try {
      clear = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(tag)),
        secretKey: await _deriveKey(password, salt, _iterationsOf(bytes)),
        aad: header,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupFailure.wrongPassword);
    }
    try {
      return BackupArchive.fromJson(jsonDecode(utf8.decode(gzip.decode(clear))) as Map<String, Object?>);
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException(BackupFailure.corrupted);
    }
  }
}
