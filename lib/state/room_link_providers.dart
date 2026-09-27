import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/online/room_link.dart';

/// D'où viennent les liens d'invitation ouverts par le système (Universal Links
/// sur iOS, App Links sur Android). Une interface, comme [OnlineTransport] : les
/// tests de widgets n'ont pas le plugin et fournissent leur propre flux.
abstract interface class RoomLinkSource {
  /// Tous les liens ouverts vers l'application, celui qui l'a lancée compris.
  Stream<Uri> get links;
}

class AppLinksRoomLinkSource implements RoomLinkSource {
  const AppLinksRoomLinkSource();

  @override
  Stream<Uri> get links => AppLinks().uriLinkStream;
}

final roomLinkSourceProvider = Provider<RoomLinkSource>((ref) => const AppLinksRoomLinkSource());

/// Le code d'un salon qu'un lien vient de proposer, en attendant que l'accueil
/// l'ouvre (voir [SetupScreen]). Un lien ne fait jamais rejoindre le salon de
/// lui-même : le joueur choisit son pseudo et touche « Rejoindre ».
class PendingRoomCode extends Notifier<String?> {
  @override
  String? build() => null;

  /// Retient le code de [link], sauf si ce n'est pas un lien d'invitation.
  void offer(Uri link) {
    final code = parseRoomLink(link);
    if (code != null) state = code;
  }

  /// Rend le code en attente, une seule fois.
  String? take() {
    final code = state;
    state = null;
    return code;
  }
}

final pendingRoomCodeProvider = NotifierProvider<PendingRoomCode, String?>(PendingRoomCode.new);

/// Écoute les liens pendant toute la vie de l'application. À regarder depuis sa
/// racine : c'est ce qui attrape le lien qui a lancé l'app à froid.
final roomLinkListenerProvider = Provider<void>((ref) {
  final pending = ref.read(pendingRoomCodeProvider.notifier);
  // Une plateforme sans liens (bureau, tests) ne doit pas faire échouer l'app.
  try {
    final subscription = ref.read(roomLinkSourceProvider).links.listen(pending.offer, onError: (Object _) {});
    ref.onDispose(subscription.cancel);
  } catch (_) {}
});
