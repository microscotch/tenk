import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/player_profile.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../state/player_providers.dart';
import '../../state/player_store.dart';
import '../../state/settings_providers.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';
import 'player_edit_screen.dart';
import 'setup_screen.dart';

/// Demande son profil à l'utilisateur, au lancement, quand il n'en a pas (voir
/// `isMyProfileMissing`) : créer sa fiche, ou désigner la sienne parmi celles
/// qui existent déjà — un utilisateur d'avant la notion de profil y figure sans
/// doute, statistiques comprises.
///
/// On ne peut pas en sortir sans profil : il n'y a ni flèche retour ni retour
/// système. Une fois le profil choisi, l'écran d'accueil prend sa place.
class MyProfileSetupScreen extends ConsumerWidget {
  const MyProfileSetupScreen({super.key});

  Future<void> _choose(BuildContext context, WidgetRef ref, PlayerProfile profile) async {
    await ref.read(settingsProvider.notifier).setMyProfileId(profile.id);
    ref.invalidate(playersProvider);
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: SetupScreen.routeName),
        builder: (_) => const SetupScreen(),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    // L'ancien nom ne préremplit que s'il est libre : une fiche qui le porte
    // déjà est proposée plus bas, et le reprendre serait refusé (nom pris).
    final players = ref.read(playersProvider).value ?? const <PlayerProfile>[];
    final legacyTaken = profileMatchingLegacyName(players, settings.playerName) != null;
    final created = await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute(
        builder: (_) => PlayerEditScreen(
          isMyProfile: true,
          initialName: legacyTaken ? null : settings.playerName,
          initialRightHanded: settings.rightHanded,
        ),
      ),
    );
    if (created == null || !context.mounted) return;
    await _choose(context, ref, created);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final players = ref.watch(playersProvider).value ?? const <PlayerProfile>[];
    // L'ancien « joueur principal » des réglages en tête : c'est très
    // probablement lui.
    final legacy = profileMatchingLegacyName(players, ref.watch(settingsProvider).playerName);
    final ordered = [?legacy, ...players.where((p) => p.id != legacy?.id)];

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppTopBar(title: Text(l10n.myProfileWelcomeTitle), automaticallyImplyLeading: false),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l10n.myProfileWelcomeMessage, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _create(context, ref),
                icon: const Icon(Icons.person_add),
                label: Text(l10n.myProfileCreateButton),
              ),
              if (ordered.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(l10n.myProfileExistingPrompt, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final player in ordered)
                  ListTile(
                    leading: PlayerAvatarWidget(name: player.name, size: 40),
                    title: Text(player.displayName),
                    subtitle: player.nickname == null ? null : Text(player.name),
                    onTap: () => _choose(context, ref, player),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Garde de lancement : l'écran d'accueil, ou d'abord [MyProfileSetupScreen]
/// si l'utilisateur n'a pas de profil. Rend la page à pousser à la place du
/// splash.
Future<Widget> launchScreenFor(ProviderContainer container) async {
  if (await isMyProfileMissing(container)) return const MyProfileSetupScreen();
  return const SetupScreen();
}
