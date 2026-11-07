import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Met l'application en plein écran **sur Android** : ni barre d'état ni barre de
/// navigation (mode immersif « collant » : un glissement depuis le bord les fait
/// réapparaître un instant, puis elles se cachent d'elles-mêmes). Le jeu occupe alors
/// tout l'écran, tapis compris. Sans effet ailleurs : sur iOS la barre d'état reste, et
/// sur un ordinateur la fenêtre est celle du système.
///
/// À rappeler quand l'application revient au premier plan : Android peut avoir
/// rendu les barres entre-temps (une autre application, un clavier, la bascule d'un
/// menu système). [platform] ne sert qu'aux tests.
Future<void> applyFullScreen({TargetPlatform? platform}) async {
  if (kIsWeb) return;
  if ((platform ?? defaultTargetPlatform) != TargetPlatform.android) return;
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
