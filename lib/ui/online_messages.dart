import '../l10n/generated/app_localizations.dart';
import '../state/online_providers.dart';

/// Le texte d'une erreur de la session en ligne, ou null quand elle n'a pas à
/// être montrée (un coup refusé parce qu'un autre a joué juste avant, par
/// exemple : l'écran est déjà à jour).
String? onlineErrorMessage(AppLocalizations l10n, ErrorCode code, {required bool unreachable}) {
  if (unreachable) return l10n.onlineErrorUnreachable;
  return switch (code) {
    ErrorCode.roomNotFound => l10n.onlineErrorRoomNotFound,
    ErrorCode.roomFull => l10n.onlineErrorRoomFull,
    ErrorCode.gameStarted => l10n.onlineErrorGameStarted,
    ErrorCode.rateLimited => l10n.onlineErrorRateLimited,
    ErrorCode.badToken => l10n.onlineErrorBadToken,
    ErrorCode.unsupportedVersion => l10n.onlineErrorUnsupportedVersion,
    ErrorCode.notYourTurn || ErrorCode.illegalMove => null,
    ErrorCode.badRequest || ErrorCode.notHost => l10n.onlineErrorGeneric,
  };
}
