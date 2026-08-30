import 'package:flutter/material.dart';

/// Titre de la barre d'app, avec une petite touche "jeu" (icône de dé).
class AppTitle extends StatelessWidget {
  const AppTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.casino, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        const Text('Le 10000'),
      ],
    );
  }
}
