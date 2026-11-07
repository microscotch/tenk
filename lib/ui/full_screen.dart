import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Met l'application en plein écran **sur Android et sur iOS**.
///
/// Android : ni barre d'état ni barre de navigation (mode immersif « collant » : un
/// glissement depuis le bord les fait réapparaître un instant, puis elles se cachent d'elles-mêmes).
/// iOS : la barre d'état est masquée, de la même façon ; la barre d'accueil, elle, ne peut pas
/// être supprimée par l'application, et l'encoche reste hors du dessin (zone sûre).
/// Le jeu occupe alors tout l'écran, tapis compris. Sans effet sur un ordinateur, où la
/// fenêtre est celle du système.
///
/// À rappeler quand l'application revient au premier plan : le système peut avoir
/// rendu les barres entre-temps (une autre application, un clavier, la bascule d'un
/// menu système). [platform] ne sert qu'aux tests.
Future<void> applyFullScreen({TargetPlatform? platform}) async {
  if (kIsWeb) return;
  final target = platform ?? defaultTargetPlatform;
  if (target != TargetPlatform.android && target != TargetPlatform.iOS) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
