import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'widgets/casino_felt_background.dart';

/// Transition d'écran : la nouvelle page glisse depuis la droite comme une
/// tuile posée sur la précédente, qui recule un peu vers la gauche (la
/// transition d'iOS, appliquée à toutes les plateformes à la place du fondu
/// d'Android).
///
/// Les écrans sont transparents (voir `buildAppTheme`) : le feutre de table est
/// peint une fois derrière le navigateur. Un glissé laisserait donc voir la page
/// qui part à travers celle qui arrive. Chaque page porte ici son propre feutre,
/// pour glisser d'un bloc, opaque — un feutre dessiné comme fixé à l'écran
/// ([ScreenFixedFeltBackground]) : seul le contenu glisse, l'éclairage du
/// tapis (dégradé, vignette) et ses losanges ne bougent pas, sans quoi le fond
/// paraît terne le temps du passage.
class FeltTileSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FeltTileSlidePageTransitionsBuilder();

  static const _slide = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => _slide.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _slide.reverseTransitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _slide.buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      Stack(children: [
        ScreenFixedFeltBackground(motion: Listenable.merge([animation, secondaryAnimation])),
        child,
      ]),
    );
  }
}

/// La même transition pour toutes les plateformes.
const PageTransitionsTheme feltTileSlideTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FeltTileSlidePageTransitionsBuilder(),
    TargetPlatform.iOS: FeltTileSlidePageTransitionsBuilder(),
    TargetPlatform.macOS: FeltTileSlidePageTransitionsBuilder(),
    TargetPlatform.linux: FeltTileSlidePageTransitionsBuilder(),
    TargetPlatform.windows: FeltTileSlidePageTransitionsBuilder(),
    TargetPlatform.fuchsia: FeltTileSlidePageTransitionsBuilder(),
  },
);
