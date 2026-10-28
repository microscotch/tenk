import 'package:le10000/game/player_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_player_store.dart';

/// Donne un profil à l'utilisateur de l'appareil : [profile] rangée dans
/// [players], et désignée par les préférences, comme après sa création au
/// premier lancement. À appeler AVANT que `settingsProvider` ne se construise
/// (il relit les préférences à ce moment-là).
///
/// [tutorialSeen] : le tutoriel a déjà été affiché sur ce téléphone (sinon le
/// lancement le propose avant l'accueil).
Future<void> seedMyProfile(FakePlayerStore players, PlayerProfile profile, {bool tutorialSeen = false}) async {
  await players.write(profile);
  SharedPreferences.setMockInitialValues({
    'settings.myProfileId': profile.id,
    'settings.themeChoice': 'dark',
    if (tutorialSeen) 'settings.tutorialSeen': true,
  });
}
