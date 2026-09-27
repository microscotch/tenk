import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Ouvre la feuille de partage du système (WhatsApp, Messages...) avec [text].
/// [origin] ancre la fenêtre flottante sur iPad, où elle est obligatoire.
///
/// Une fonction derrière un fournisseur plutôt qu'un appel direct : les tests
/// de widgets remplacent le plugin, qui n'existe pas dans leur environnement.
typedef ShareText = Future<void> Function(String text, {Rect? origin});

final shareTextProvider = Provider<ShareText>(
  (ref) => (text, {origin}) => SharePlus.instance.share(ShareParams(text: text, sharePositionOrigin: origin)),
);
