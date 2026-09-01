/// Raison pour laquelle une tentative de banquer le score du tour échoue.
enum BankFailureReason {
  /// Le score du tour n'atteint pas le minimum requis (500 hors jeu, 200 une
  /// fois entré).
  belowMinimum,

  /// Le score du tour se termine par 50 : interdiction de s'arrêter.
  endsIn50,

  /// Le joueur vient de faire un "dés chauds" : il est obligé de relancer.
  mustContinueHotDice,

  /// Aucun lancer n'a encore eu lieu ce tour-ci (début de tour, y compris sur
  /// une main héritée dont le score de base atteindrait déjà le minimum) :
  /// il faut d'abord lancer les dés avant de pouvoir s'arrêter.
  notRolledYet,

  /// S'arrêter maintenant laisserait un score total strictement inférieur à
  /// 10000 mais à moins du minimum requis (200 une fois entré) de la cible :
  /// aucun tour futur ne pourrait alors plus jamais atteindre exactement
  /// 10000 (le minimum par tour l'en empêcherait systématiquement). Ne
  /// s'applique jamais si le score total atteindrait exactement 10000 : ce
  /// cas-là est toujours autorisé, y compris en dés chauds.
  wouldMakeWinningImpossible,
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
