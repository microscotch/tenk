import 'package:flutter/material.dart';

/// La barre du haut de TOUS les écrans : un [AppBar], sans flèche de retour sur
/// Android, où le bouton (ou le geste) retour du système s'en charge.
///
/// Ailleurs, la flèche automatique de Flutter reste : iOS n'a pas de retour
/// système, et le bureau non plus. Un écran qui écarte la flèche pour ses
/// propres raisons ([automaticallyImplyLeading] faux) le reste partout.
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

  /// Vrai quand la flèche de retour automatique a sa place sur la plateforme
  /// du thème : partout sauf sur Android.
  static bool impliesBackButton(BuildContext context) =>
      Theme.of(context).platform != TargetPlatform.android;

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
      automaticallyImplyLeading: automaticallyImplyLeading && impliesBackButton(context),
    );
  }
}
