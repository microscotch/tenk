import 'dart:math';

/// Lance [count] dés à 6 faces. Le générateur aléatoire est injectable pour
/// permettre des tests déterministes du moteur de jeu.
List<int> rollDice(int count, [Random? random]) {
  assert(count >= 1 && count <= 5);
  final rng = random ?? Random();
  return List.generate(count, (_) => rng.nextInt(6) + 1);
}

/// Enveloppe un [Random] et mémorise chaque `nextInt(6)` qu'il rend, dans
/// l'ordre : le serveur d'une partie en ligne joue un lancer avec, puis diffuse
/// [faces] aux clients — qui n'ont jamais la seed, donc ne peuvent rien prédire.
class RecordingRandom implements Random {
  final Random _inner;
  final List<int> _values = [];

  RecordingRandom(this._inner);

  /// Les faces (1 à 6) tirées depuis la dernière remise à zéro.
  List<int> get faces => List.unmodifiable(_values);

  /// Oublie ce qui a été enregistré, pour isoler le lancer suivant.
  void clear() => _values.clear();

  @override
  int nextInt(int max) {
    assert(max == 6, 'seuls les dés à 6 faces sont enregistrables');
    final value = _inner.nextInt(max);
    _values.add(value + 1);
    return value;
  }

  @override
  double nextDouble() => throw UnsupportedError('RecordingRandom ne rend que des faces de dé');

  @override
  bool nextBool() => throw UnsupportedError('RecordingRandom ne rend que des faces de dé');
}

/// Rend, dans l'ordre, des faces déjà tirées ailleurs : c'est ainsi qu'un client
/// rejoue un lancer décidé par le serveur, avec le même moteur que le jeu local.
///
/// Lève une [StateError] si le moteur demande plus de dés que fournis ou si des
/// faces restent inutilisées ([assertConsumed]) : un lancer qui ne colle pas à
/// l'état du client est un désaccord à signaler, pas à absorber en silence.
class ScriptedRandom implements Random {
  final List<int> _faces;
  var _next = 0;

  ScriptedRandom(List<int> faces) : _faces = List.of(faces) {
    for (final face in _faces) {
      if (face < 1 || face > 6) throw ArgumentError.value(face, 'faces', 'une face de dé va de 1 à 6');
    }
  }

  @override
  int nextInt(int max) {
    if (max != 6) throw StateError('ScriptedRandom ne rend que des faces de dé (max 6, reçu $max)');
    if (_next >= _faces.length) throw StateError('le moteur demande plus de dés que les ${_faces.length} reçus');
    return _faces[_next++] - 1;
  }

  /// Vérifie que toutes les faces ont servi.
  void assertConsumed() {
    if (_next != _faces.length) {
      throw StateError('${_faces.length - _next} face(s) reçue(s) sur ${_faces.length} n\'ont pas servi');
    }
  }

  @override
  double nextDouble() => throw UnsupportedError('ScriptedRandom ne rend que des faces de dé');

  @override
  bool nextBool() => throw UnsupportedError('ScriptedRandom ne rend que des faces de dé');
}
