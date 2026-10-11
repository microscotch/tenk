import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../state/online_providers.dart';
import '../../game/online/protocol.dart' show isValidOnlineName;
import '../../game/player_profile.dart';
import '../../state/player_providers.dart';
import '../../state/player_store.dart';
import '../online_messages.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/player_avatar.dart';
import 'player_edit_screen.dart';
import 'online_dice_off_screen.dart';
import 'online_room_screen.dart';

/// L'entrée des parties en ligne : créer un salon, ou rejoindre celui dont on a
/// le code. Quand une partie en ligne est déjà en cours, on la retrouve (ou on
/// la quitte) ici plutôt que d'en ouvrir une seconde.
///
/// Le pseudo n'est pas saisi : c'est le nom affiché du profil de l'utilisateur
/// (`myProfileProvider`), qu'on modifie depuis ici ou les réglages. S'il ne
/// passe pas les règles du serveur, créer et rejoindre restent bloqués jusqu'à
/// ce que le profil soit corrigé.
class OnlineEntryScreen extends ConsumerStatefulWidget {
  /// Le code d'un lien d'invitation, déjà saisi : il reste au joueur à toucher
  /// « Rejoindre » (un lien ne rejoint jamais seul).
  final String? initialCode;

  const OnlineEntryScreen({super.key, this.initialCode});

  @override
  ConsumerState<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends ConsumerState<OnlineEntryScreen> {
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode);
    // La partie en ligne d'avant est terminée : il n'y a rien à reprendre, on
    // quitte son salon et l'écran propose d'en créer ou d'en rejoindre un.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(onlineSessionProvider.notifier).leaveFinishedGame();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  /// Mon pseudo en ligne : le nom affiché de mon profil, s'il est utilisable.
  String? get _onlineName {
    final name = ref.watch(myProfileProvider)?.displayName;
    return name != null && isValidOnlineName(name) ? name.trim() : null;
  }

  Future<void> _editProfile() async {
    final me = ref.read(myProfileProvider);
    await Navigator.of(context).push<PlayerProfile>(
      MaterialPageRoute(builder: (_) => PlayerEditScreen(existing: me, isMyProfile: true)),
    );
    ref.invalidate(playersProvider);
  }

  /// Ouvre l'écran qui correspond à l'état de la session : le salon, ou la
  /// partie déjà commencée. Si le [GameNotifier] a servi à autre chose depuis
  /// (une partie locale, un rejeu), la partie en ligne y est d'abord remise en
  /// place à partir du journal du serveur.
  Future<void> _openCurrent() async {
    final session = ref.read(onlineSessionProvider.notifier);
    final started = ref.read(onlineSessionProvider).gameStarted;
    if (started && !await session.reopenGame()) return;
    if (!mounted) return;
    final Widget screen = started ? const OnlineDiceOffScreen() : const OnlineRoomScreen();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final before = ref.read(onlineSessionProvider);
    final inGame = before.gameStarted && before.phase != RoomPhase.over;
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.onlineLeaveConfirmTitle),
        // Dans une partie commencée, le serveur fait reprendre ma place par un
        // bot (voir seatBotsFeature) ; un serveur d'avant la laisse vide et
        // attend mon retour.
        content: Text(inGame && before.seatBotsEnabled ? l10n.onlineLeaveGameBody : l10n.onlineLeaveConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancelButton)),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.onlineLeaveButton)),
        ],
      ),
    );
    if (leave != true) return;
    final online = ref.read(onlineSessionProvider);
    final session = ref.read(onlineSessionProvider.notifier);
    // Une partie commencée se quitte comme le dit la fenêtre (pour de bon, un
    // bot prenant la place ; ou en la gardant, face à un serveur d'avant) ; un
    // salon qui n'a pas commencé, ou une partie finie, se quitte tout court.
    if (online.gameStarted && online.phase != RoomPhase.over) {
      await session.leaveGame();
    } else {
      await session.leave();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final online = ref.watch(onlineSessionProvider);
    ref.listen<OnlineState>(onlineSessionProvider, (previous, next) {
      if (next.errorSerial != (previous?.errorSerial ?? 0) && next.error != null) {
        final message = onlineErrorMessage(l10n, next.error!, unreachable: next.unreachable);
        if (message != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      // Le serveur vient de décrire le salon pour la première fois : on y va.
      if (previous?.phase == null && next.phase != null && next.roomCode != null) {
        // Revenu dans un salon dont la partie est finie (l'app avait été fermée
        // avant de l'apprendre) : rien à y voir, on en sort.
        if (next.phase == RoomPhase.over) {
          ref.read(onlineSessionProvider.notifier).leaveFinishedGame();
        } else {
          _openCurrent();
        }
      }
    });

    final connecting = online.status == OnlineStatus.connecting;
    return Scaffold(
      appBar: AppTopBar(title: Text(l10n.onlineTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: online.inRoom && online.phase != RoomPhase.over ? _inRoom(l10n, online) : _entry(l10n, connecting),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inRoom(AppLocalizations l10n, OnlineState online) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(online.roomCode!, style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _openCurrent,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.onlineResumeButton),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _confirmLeave,
          icon: const Icon(Icons.logout),
          label: Text(l10n.onlineLeaveButton),
        ),
      ],
    );
  }

  Widget _entry(AppLocalizations l10n, bool connecting) {
    final session = ref.read(onlineSessionProvider.notifier);
    final saved = ref.watch(onlineSavedGameProvider).value;
    final name = _onlineName;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Une place gardée dans une partie en ligne (déconnexion volontaire,
        // app fermée) : la retrouver passe avant d'en ouvrir une autre.
        if (saved != null) ...[
          FilledButton.icon(
            onPressed: connecting ? null : session.tryResume,
            icon: const Icon(Icons.play_arrow),
            label: Text(l10n.onlineResumeButton),
          ),
          const SizedBox(height: 24),
        ],
        _identity(l10n, name),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: connecting || name == null ? null : () => session.create(name),
          icon: const Icon(Icons.add),
          label: Text(l10n.onlineCreateButton),
        ),
        const SizedBox(height: 24),
        Row(children: [
          const Expanded(child: Divider()),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l10n.onlineOrDivider)),
          const Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),
        TextField(
          controller: _code,
          maxLength: 5,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(labelText: l10n.onlineCodeLabel, border: const OutlineInputBorder()),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: connecting || name == null || _code.text.trim().length != 5
              ? null
              : () => session.join(_code.text, name),
          icon: const Icon(Icons.login),
          label: Text(l10n.onlineJoinButton),
        ),
        if (connecting) ...[
          const SizedBox(height: 24),
          Center(child: Text(l10n.onlineConnecting)),
        ],
      ],
    );
  }

  /// Sous quel nom je joue, et de quoi le changer ; ou, quand le nom de mon
  /// profil ne peut pas servir en ligne, pourquoi.
  Widget _identity(AppLocalizations l10n, String? name) {
    final me = ref.watch(myProfileProvider);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          PlayerAvatarWidget(name: me?.name ?? '?', size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: name != null
                ? Text(l10n.onlinePlayingAs(name), style: theme.textTheme.titleMedium)
                : Text(l10n.onlineNameInvalidError, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ]),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: me == null ? null : _editProfile,
            icon: const Icon(Icons.edit),
            label: Text(l10n.myProfileEditButton),
          ),
        ),
      ],
    );
  }
}
