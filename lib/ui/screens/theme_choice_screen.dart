import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/settings_providers.dart';
import '../theme.dart';
import '../widgets/app_top_bar.dart';
import 'setup_screen.dart';

/// Propose l'apparence de l'application, au premier lancement qui suit
/// l'ajout du réglage (voir `launchScreenFor`) : tant que [AppSettings.themeChoice]
/// est nul. Toucher une vignette applique le thème tout de suite, pour qu'on le
/// voie avant de valider ; « Continuer » ouvre la page [next].
///
/// Pas de flèche retour ni de retour système : le choix se fait une fois, et se
/// refait dans les réglages.
class ThemeChoiceScreen extends ConsumerWidget {
  final Widget next;

  const ThemeChoiceScreen({super.key, required this.next});

  void _continue(BuildContext context, WidgetRef ref, ThemeChoice choice) {
    // Même si l'utilisateur n'a rien touché : continuer valide le thème affiché.
    ref.read(settingsProvider.notifier).setThemeChoice(choice);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: next is SetupScreen ? const RouteSettings(name: SetupScreen.routeName) : null,
        builder: (_) => next,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final shown = ref.watch(settingsProvider.select((s) => s.themeChoice)) ?? ThemeChoice.dark;
    final notifier = ref.read(settingsProvider.notifier);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppTopBar(title: Text(l10n.themeChoiceTitle), automaticallyImplyLeading: false),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.themeChoiceMessage, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ThemeSwatchCard(
                          choice: ThemeChoice.dark,
                          label: l10n.themeDark,
                          selected: shown == ThemeChoice.dark,
                          onTap: () => notifier.setThemeChoice(ThemeChoice.dark),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ThemeSwatchCard(
                          choice: ThemeChoice.light,
                          label: l10n.themeLight,
                          selected: shown == ThemeChoice.light,
                          onTap: () => notifier.setThemeChoice(ThemeChoice.light),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _continue(context, ref, shown),
                  child: Text(l10n.themeChoiceContinue),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Une vignette de thème : un morceau de son feutre, quelques dés dorés posés
/// dessus, et son nom. Dessinée avec les couleurs du thème qu'elle représente
/// (pas celles du thème en cours), cerclée d'or quand elle est choisie.
class ThemeSwatchCard extends StatelessWidget {
  final ThemeChoice choice;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const ThemeSwatchCard({
    super.key,
    required this.choice,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = choice == ThemeChoice.light ? TableColors.light : TableColors.dark;
    final scheme = themeFor(choice).colorScheme;
    final accent = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? accent : Colors.transparent, width: 3),
            gradient: RadialGradient(
              center: const Alignment(0, -0.3),
              radius: 1.2,
              colors: [colors.feltCenter, colors.feltEdge],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.casino, size: 56, color: scheme.primary),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(12)),
                child: Text(label, style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? accent : colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
