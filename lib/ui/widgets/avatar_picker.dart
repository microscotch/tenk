import 'package:flutter/material.dart';

import '../../game/avatar_catalog.dart';
import '../../game/avatar_initials.dart';
import '../../l10n/generated/app_localizations.dart';
import 'player_avatar.dart';

/// Le choix de la pastille dans le profil : une rangée de couleurs (la première,
/// « Automatique », laisse la partie en attribuer une) et une grille d'animaux (la
/// première montre la lettre du joueur, c'est-à-dire pas d'animal). Les choix sont
/// des identifiants de `avatar_catalog.dart`, `null` pour « automatique » / « lettre ».
///
/// Sans état : le parent garde les choix et redessine ([PlayerAvatarWidget] en
/// aperçu au-dessus).
class AvatarPicker extends StatelessWidget {
  /// Le nom affiché du joueur, dont vient la lettre.
  final String name;
  final String? color;
  final String? animal;
  final ValueChanged<String?> onColor;
  final ValueChanged<String?> onAnimal;

  const AvatarPicker({
    super.key,
    required this.name,
    required this.color,
    required this.animal,
    required this.onColor,
    required this.onAnimal,
  });

  static const double _cell = 40;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // La couleur sous la lettre et sous l'animal : celle qui est choisie, sinon celle
    // que la partie donnerait à ce nom.
    final shown = avatarColorById(color) != null ? Color(avatarColorById(color)!.argb) : avatarColorFor(name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.avatarColorLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Cell(
              key: const ValueKey('avatar-color-auto'),
              selected: color == null,
              label: l10n.avatarAutomatic,
              onTap: () => onColor(null),
              child: Icon(Icons.auto_awesome, size: 20, color: theme.colorScheme.onSurface),
            ),
            for (final c in avatarColorChoices)
              _Cell(
                key: ValueKey('avatar-color-${c.id}'),
                selected: color == c.id,
                onTap: () => onColor(c.id),
                fill: Color(c.argb),
                child: color == c.id ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(l10n.avatarAnimalLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Cell(
              key: const ValueKey('avatar-animal-none'),
              selected: avatarAnimalById(animal) == null,
              label: l10n.avatarLetter,
              onTap: () => onAnimal(null),
              fill: shown,
              child: Text(
                avatarLetterFor(name),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20, height: 1),
              ),
            ),
            for (final a in avatarAnimalChoices)
              _Cell(
                key: ValueKey('avatar-animal-${a.id}'),
                selected: animal == a.id,
                onTap: () => onAnimal(a.id),
                fill: shown,
                child: Text(a.emoji, style: const TextStyle(fontSize: 22, height: 1, fontFamilyFallback: kEmojiFontFallback)),
              ),
          ],
        ),
      ],
    );
  }
}

/// Une case ronde du sélecteur : [fill] pour le fond (sinon un contour), cerclée de
/// l'accent quand elle est [selected]. [label] : son nom pour les lecteurs d'écran.
class _Cell extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Color? fill;
  final String? label;
  final Widget? child;

  const _Cell({super.key, required this.selected, required this.onTap, this.fill, this.label, this.child});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final outline = Theme.of(context).colorScheme.outline;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label ?? '',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: AvatarPicker._cell,
            height: AvatarPicker._cell,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fill,
              shape: BoxShape.circle,
              border: Border.all(color: selected ? accent : outline, width: selected ? 3 : 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
