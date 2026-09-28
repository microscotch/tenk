import 'package:le10000/game/player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_player_store.dart';

/// Donne un profil à l'utilisateur de l'appareil : [profile] rangée dans
/// [players], et désignée par les préférences, comme après sa création au
/// premier lancement. À appeler AVANT que `settingsProvider` ne se construise
/// (il relit les préférences à ce moment-là).
Future<void> seedMyProfile(FakePlayerStore players, PlayerProfile profile) async {
  await players.write(profile);
  SharedPreferences.setMockInitialValues({'settings.myProfileId': profile.id});
}
