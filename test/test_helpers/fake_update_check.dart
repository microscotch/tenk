import 'package:le10000/state/update_check.dart';

/// Un `latest.json` dont les builds sont disponibles depuis longtemps.
String latestJson({int? android, int? ios}) {
  String entry(int build) => '{"version": "1.0.0", "build": $build, "availableFrom": "2026-01-01T00:00:00Z"}';
  return '{${[if (android != null) '"android": ${entry(android)}', if (ios != null) '"ios": ${entry(ios)}'].join(', ')}}';
}

/// Un appareil et un réseau scriptés pour la vérification des mises à jour.
class FakeUpdateCheckEnvironment implements UpdateCheckEnvironment {
  @override
  final StorePlatform? platform;
  final int? installed;
  final String? latest;
  int? dismissed;
  int fetches = 0;

  FakeUpdateCheckEnvironment({this.platform = StorePlatform.android, this.installed, this.latest, this.dismissed});

  @override
  Future<int?> installedBuild() async => installed;

  @override
  Future<String?> fetchLatestBuilds() async {
    fetches++;
    return latest;
  }

  @override
  Future<int?> dismissedBuild() async => dismissed;

  @override
  Future<void> saveDismissedBuild(int build) async => dismissed = build;
}
