import 'package:flutter/material.dart';

/// Titre de l'app, avec une petite touche "jeu" (icône de dé) : dans la barre
/// du haut, ou en grand ([large]) en tête de l'écran d'accueil, qui n'a pas de
/// barre.
class AppTitle extends StatelessWidget {
  final bool large;

  const AppTitle({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.casino, color: theme.colorScheme.primary, size: large ? 44 : null),
        SizedBox(width: large ? 14 : 10),
        Text(
          'TenK',
          // En grand, le style de titre de la barre (voir le thème), agrandi —
          // avec un repli équivalent si le thème n'en définit pas ; dans la
          // barre, celle-ci l'applique déjà.
          style: large
              ? (theme.appBarTheme.titleTextStyle ?? const TextStyle(fontWeight: FontWeight.w900))
                  .copyWith(fontSize: 44, color: theme.colorScheme.primary)
              : null,
        ),
      ],
    );
  }
}
