import 'package:flutter/material.dart';

/// La barre du haut de TOUS les écrans : un [AppBar], avec la flèche de retour
/// automatique de Flutter **sur toutes les plateformes**.
///
/// Android en avait été privé, le bouton (ou le geste) retour du système s'en chargeant ;
/// mais l'application y est en plein écran (voir `applyFullScreen`), barre de navigation
/// cachée : la flèche est redevenue le retour visible. Un écran qui écarte la flèche pour
/// ses propres raisons ([automaticallyImplyLeading] faux) le reste partout.
///
/// Tout nouvel écran passe par ce widget plutôt que par [AppBar] directement :
/// un test (`test/ui/app_top_bar_test.dart`) refuse tout `AppBar(` ailleurs
/// dans `lib/ui`.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;

  const AppTopBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
  });

  /// La taille que calcule [AppBar] lui-même : [Scaffold] la reconnaît et y
  /// applique la hauteur de barre du thème, exactement comme pour un [AppBar].
  @override
  Size get preferredSize => AppBar().preferredSize;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
    );
  }
}
