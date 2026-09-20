import 'ai/ai_profiles.dart';

/// Configuration d'une partie : les noms des joueurs, pour chacun
/// éventuellement une difficulté d'IA (absent d'index = joueur humain), et
/// l'ensemble des joueurs en "mode auto" (leurs actions se valident seules
/// après le délai réglé dans les préférences ; sinon un bouton explicite
/// attend toujours un clic manuel).
class GameSetup {
  final List<String> playerNames;
  final Map<int, AiDifficulty> aiPlayers;
  final Set<int> autoPlayers;

  /// Fiche de la base à laquelle chaque siège humain est rattaché, par index
  /// de siège — même forme que [aiPlayers] : un siège absent n'est rattaché à
  /// personne, ce qui est le cas de tout bot et de toute partie enregistrée
  /// avant l'existence de la base.
  ///
  /// C'est ce lien, et non le nom, qui rattache une partie à un joueur : un
  /// renommage ne doit rien casser.
  final Map<int, String> playerIds;

  const GameSetup({
    required this.playerNames,
    this.aiPlayers = const {},
    this.autoPlayers = const {},
    this.playerIds = const {},
  });

  bool isAi(int index) => aiPlayers.containsKey(index);
  bool isAuto(int index) => autoPlayers.contains(index);

  /// Identifiant de fiche du siège [index], ou `null` s'il n'est rattaché à
  /// aucune (bot, ou partie antérieure à la base de joueurs).
  String? playerIdAt(int index) => playerIds[index];

  /// Réordonne les joueurs pour que [winnerIndex] (vainqueur du tirage au
  /// sort) devienne l'index 0, en conservant la correspondance IA/auto de
  /// chaque joueur d'origine.
  GameSetup rotated(int winnerIndex) {
    final n = playerNames.length;
    final rotatedNames = [for (var i = 0; i < n; i++) playerNames[(winnerIndex + i) % n]];
    final rotatedAi = <int, AiDifficulty>{};
    aiPlayers.forEach((origIndex, difficulty) {
      rotatedAi[(origIndex - winnerIndex + n) % n] = difficulty;
    });
    final rotatedAuto = {for (final origIndex in autoPlayers) (origIndex - winnerIndex + n) % n};
    final rotatedIds = <int, String>{};
    playerIds.forEach((origIndex, id) => rotatedIds[(origIndex - winnerIndex + n) % n] = id);
    return GameSetup(
      playerNames: rotatedNames,
      aiPlayers: rotatedAi,
      autoPlayers: rotatedAuto,
      playerIds: rotatedIds,
    );
  }
}
