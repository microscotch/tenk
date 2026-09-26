/// Seau à jetons : [ratePerSecond] jetons par seconde, jusqu'à [burst]. Sert à
/// borner ce qu'une connexion ou une adresse peut demander au serveur.
class TokenBucket {
  final double ratePerSecond;
  final int burst;
  final DateTime Function() _now;

  double _tokens;
  DateTime _last;

  TokenBucket({required this.ratePerSecond, required this.burst, DateTime Function()? now})
      : _now = now ?? DateTime.now,
        _tokens = burst.toDouble(),
        _last = (now ?? DateTime.now)();

  /// Prend un jeton s'il en reste ; faux si la limite est atteinte.
  bool tryTake() {
    final now = _now();
    final elapsed = now.difference(_last).inMicroseconds / 1e6;
    _last = now;
    _tokens = (_tokens + elapsed * ratePerSecond).clamp(0, burst).toDouble();
    if (_tokens < 1) return false;
    _tokens -= 1;
    return true;
  }
}

/// Réglages du serveur, tous surchargeables (les tests réduisent les délais).
class ServerConfig {
  /// Salons ouverts en même temps, au total.
  final int maxRooms;

  /// Connexions simultanées depuis une même adresse.
  final int maxConnectionsPerIp;

  /// Messages par seconde acceptés d'une connexion (avec une rafale de [messageBurst]).
  final double messagesPerSecond;
  final int messageBurst;

  /// Taille maximale d'un message reçu, en octets.
  final int maxMessageBytes;

  /// Échecs de jointure (code inconnu, jeton inconnu) tolérés par minute et par
  /// adresse : au-delà, on ne répond plus qu'« essayez plus tard ». C'est ce qui
  /// rend un code de salon impossible à deviner par essais.
  final int joinFailuresPerMinute;

  /// Salons créés par minute et par adresse.
  final int roomsCreatedPerMinute;

  /// Un joueur déconnecté depuis plus longtemps suspend la partie (et perd son
  /// siège dans un salon qui n'a pas commencé).
  final Duration reconnectGrace;

  /// Inactivité au bout de laquelle un salon disparaît, selon son étape.
  final Duration lobbyIdleTtl;
  final Duration gameIdleTtl;
  final Duration finishedTtl;

  const ServerConfig({
    this.maxRooms = 500,
    this.maxConnectionsPerIp = 12,
    this.messagesPerSecond = 10,
    this.messageBurst = 20,
    this.maxMessageBytes = 4096,
    this.joinFailuresPerMinute = 10,
    this.roomsCreatedPerMinute = 5,
    this.reconnectGrace = const Duration(minutes: 2),
    this.lobbyIdleTtl = const Duration(minutes: 30),
    this.gameIdleTtl = const Duration(hours: 24),
    this.finishedTtl = const Duration(minutes: 10),
  });
}
