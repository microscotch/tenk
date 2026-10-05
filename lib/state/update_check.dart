import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'online_providers.dart';

/// Où l'application apprend le dernier build arrivé sur chaque store : la route
/// `/latest-build` du serveur des parties en ligne, à côté de `/ws`
/// (`wss://hôte/ws` → `https://hôte/latest-build`). Le serveur y relaie le
/// fichier que la CI met à jour après un envoi réussi (voir
/// `tool/publish_store_build.sh`) : l'application ne contacte que lui.
Uri latestBuildUrlFor(String serverUrl) {
  final server = Uri.parse(serverUrl);
  return server.replace(scheme: server.scheme == 'ws' ? 'http' : 'https', path: '/latest-build', query: null);
}

/// Le store d'où vient l'application installée, et donc ses mises à jour.
enum StorePlatform {
  /// Google Play (piste de test interne).
  android,

  /// TestFlight.
  ios,
}

/// L'adresse qui ouvre la mise à jour : la fiche Play de l'application, ou
/// l'application TestFlight (qui ne se laisse pas ouvrir sur une app précise sans
/// son identifiant App Store, et liste de toute façon celles du testeur).
Uri storeUrlFor(StorePlatform platform) => switch (platform) {
  StorePlatform.android => Uri.parse('https://play.google.com/store/apps/details?id=net.microscotch.games.tenk'),
  StorePlatform.ios => Uri.parse('itms-beta://'),
};

/// Un build annoncé sur un store : sa version, son numéro (`versionCode` /
/// `CFBundleVersion`, le seul qui compte pour comparer) et l'instant à partir
/// duquel le store le propose (le temps qu'il le traite).
class PublishedBuild {
  final String version;
  final int build;
  final DateTime availableFrom;

  const PublishedBuild({required this.version, required this.build, required this.availableFrom});

  /// L'entrée de [platform] dans le `latest.json` de [body], ou nul si elle
  /// manque ou ne se lit pas : un fichier inattendu ne doit rien afficher, ni
  /// faire planter le lancement.
  static PublishedBuild? parse(String body, StorePlatform platform) {
    try {
      final map = jsonDecode(body);
      if (map is! Map) return null;
      final entry = map[platform.name];
      if (entry is! Map) return null;
      final version = entry['version'];
      final build = entry['build'];
      final availableFrom = DateTime.tryParse(entry['availableFrom'] as String? ?? '');
      if (version is! String || build is! int || availableFrom == null) return null;
      return PublishedBuild(version: version, build: build, availableFrom: availableFrom);
    } catch (_) {
      return null;
    }
  }
}

/// La mise à jour à proposer, s'il y en a une : un build plus récent que
/// [installedBuild], déjà disponible à [now], et que le joueur n'a pas déjà
/// écarté (« Plus tard » écarte ce build-là, pas les suivants).
PublishedBuild? updateToOffer({
  required int installedBuild,
  required PublishedBuild? published,
  required int? dismissedBuild,
  required DateTime now,
}) {
  if (published == null || published.build <= installedBuild) return null;
  if (dismissedBuild != null && dismissedBuild >= published.build) return null;
  if (now.isBefore(published.availableFrom)) return null;
  return published;
}

/// Tout ce que la vérification demande à l'appareil et au réseau. Une
/// interface, comme `RoomLinkSource` : les tests n'ont ni plugin ni réseau.
abstract interface class UpdateCheckEnvironment {
  /// Le store de l'application installée ; nul quand il n'y en a pas (bureau,
  /// build de debug lancé depuis l'ordinateur) : rien n'est alors vérifié.
  StorePlatform? get platform;

  /// Le numéro de build de l'application installée.
  Future<int?> installedBuild();

  /// Le contenu de `latest.json`, ou nul si on ne l'a pas eu.
  Future<String?> fetchLatestBuilds();

  /// Le dernier build que le joueur a écarté.
  Future<int?> dismissedBuild();

  Future<void> saveDismissedBuild(int build);
}

class DeviceUpdateCheckEnvironment implements UpdateCheckEnvironment {
  /// Voir [latestBuildUrlFor].
  final Uri latestBuildUrl;

  const DeviceUpdateCheckEnvironment(this.latestBuildUrl);

  static const _dismissedKey = 'update.dismissedBuild';

  @override
  StorePlatform? get platform {
    // Un build de debug n'a pas été installé par un store : il serait toujours
    // « en retard » sur celui-ci.
    if (kDebugMode) return null;
    if (Platform.isAndroid) return StorePlatform.android;
    if (Platform.isIOS) return StorePlatform.ios;
    return null;
  }

  @override
  Future<int?> installedBuild() async => int.tryParse((await PackageInfo.fromPlatform()).buildNumber);

  @override
  Future<String?> fetchLatestBuilds() async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client.getUrl(latestBuildUrl);
      final response = await request.close().timeout(const Duration(seconds: 10));
      if (response.statusCode != HttpStatus.ok) return null;
      return await response.transform(utf8.decoder).join().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Hors ligne, serveur injoignable : on retentera au prochain lancement.
      return null;
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<int?> dismissedBuild() async {
    try {
      return (await SharedPreferences.getInstance()).getInt(_dismissedKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDismissedBuild(int build) async {
    try {
      await (await SharedPreferences.getInstance()).setInt(_dismissedKey, build);
    } catch (_) {}
  }
}

final updateCheckEnvironmentProvider = Provider<UpdateCheckEnvironment>(
  (ref) => DeviceUpdateCheckEnvironment(latestBuildUrlFor(ref.read(onlineServerUrlProvider))),
);

/// La mise à jour à proposer au lancement (voir [updateToOffer]), ou nul. Vérifiée
/// une fois par lancement de l'application ; n'échoue jamais : tout incident
/// (réseau, fichier illisible) revient à « pas de mise à jour ».
class AvailableUpdate extends AsyncNotifier<PublishedBuild?> {
  @override
  Future<PublishedBuild?> build() async {
    final environment = ref.read(updateCheckEnvironmentProvider);
    final platform = environment.platform;
    if (platform == null) return null;
    try {
      final installed = await environment.installedBuild();
      if (installed == null) return null;
      final body = await environment.fetchLatestBuilds();
      if (body == null) return null;
      return updateToOffer(
        installedBuild: installed,
        published: PublishedBuild.parse(body, platform),
        dismissedBuild: await environment.dismissedBuild(),
        now: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  /// « Plus tard » : n'en reparle plus pour ce build, seulement pour un suivant.
  Future<void> dismiss() async {
    final update = state.value;
    if (update == null) return;
    state = const AsyncData(null);
    await ref.read(updateCheckEnvironmentProvider).saveDismissedBuild(update.build);
  }
}

final availableUpdateProvider = AsyncNotifierProvider<AvailableUpdate, PublishedBuild?>(AvailableUpdate.new);
