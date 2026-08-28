/// Raison pour laquelle une tentative de banquer le score du tour échoue.
enum BankFailureReason {
  /// Le score du tour n'atteint pas le minimum requis (500 hors jeu, 200 une
  /// fois entré).
  belowMinimum,

  /// Le score du tour se termine par 50 : interdiction de s'arrêter.
  endsIn50,

  /// Le joueur vient de faire un "dés chauds" : il est obligé de relancer.
  mustContinueHotDice,
}

/// Résultat d'une tentative de banquer (valider) le score du tour en cours.
class BankAttempt {
  final bool success;
  final BankFailureReason? reason;
  final int? bankedPoints;

  const BankAttempt.success(this.bankedPoints)
      : success = true,
        reason = null;

  const BankAttempt.failure(this.reason)
      : success = false,
        bankedPoints = null;
}
