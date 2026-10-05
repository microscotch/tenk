import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/state/update_check.dart';

import '../test_helpers/fake_update_check.dart';

void main() {
  final past = DateTime.utc(2026, 10, 5, 1);
  final now = DateTime.utc(2026, 10, 5, 2);

  group('PublishedBuild.parse', () {
    const body =
        '{"android": {"version": "1.0.0", "build": 95, "availableFrom": "2026-10-05T01:00:00Z"},'
        ' "ios": {"version": "1.0.1", "build": 96, "availableFrom": "2026-10-05T01:30:00Z"}}';

    test('lit l\'entrée de sa plateforme', () {
      final android = PublishedBuild.parse(body, StorePlatform.android)!;
      expect((android.version, android.build, android.availableFrom), ('1.0.0', 95, past));
      expect(PublishedBuild.parse(body, StorePlatform.ios)!.build, 96);
    });

    test('rend nul sur une entrée absente ou un fichier inattendu', () {
      expect(
        PublishedBuild.parse(
          '{"ios": {"version": "1.0.0", "build": 95, "availableFrom": "2026-10-05T01:00:00Z"}}',
          StorePlatform.android,
        ),
        isNull,
      );
      expect(
        PublishedBuild.parse(
          '{"android": {"version": "1.0.0", "build": "95", "availableFrom": "2026-10-05T01:00:00Z"}}',
          StorePlatform.android,
        ),
        isNull,
      );
      expect(PublishedBuild.parse('{"android": {"version": "1.0.0", "build": 95}}', StorePlatform.android), isNull);
      expect(PublishedBuild.parse('<html>404</html>', StorePlatform.android), isNull);
      expect(PublishedBuild.parse('[]', StorePlatform.android), isNull);
    });
  });

  group('updateToOffer', () {
    final published = PublishedBuild(version: '1.0.0', build: 95, availableFrom: past);

    test('propose un build plus récent, déjà disponible', () {
      expect(updateToOffer(installedBuild: 94, published: published, dismissedBuild: null, now: now), published);
    });

    test('ne propose ni le build installé ni un plus ancien', () {
      expect(updateToOffer(installedBuild: 95, published: published, dismissedBuild: null, now: now), isNull);
      expect(updateToOffer(installedBuild: 96, published: published, dismissedBuild: null, now: now), isNull);
    });

    test('attend que le store ait traité le build', () {
      expect(
        updateToOffer(
          installedBuild: 94,
          published: published,
          dismissedBuild: null,
          now: past.subtract(const Duration(minutes: 1)),
        ),
        isNull,
      );
      expect(updateToOffer(installedBuild: 94, published: published, dismissedBuild: null, now: past), published);
    });

    test('« Plus tard » écarte ce build, pas le suivant', () {
      expect(updateToOffer(installedBuild: 94, published: published, dismissedBuild: 95, now: now), isNull);
      expect(updateToOffer(installedBuild: 93, published: published, dismissedBuild: 94, now: now), published);
    });

    test('rien sans annonce', () {
      expect(updateToOffer(installedBuild: 94, published: null, dismissedBuild: null, now: now), isNull);
    });
  });

  group('availableUpdateProvider', () {
    ProviderContainer containerWith(FakeUpdateCheckEnvironment environment) {
      final container = ProviderContainer(overrides: [updateCheckEnvironmentProvider.overrideWithValue(environment)]);
      addTearDown(container.dispose);
      return container;
    }

    test('propose le build annoncé pour la plateforme de l\'appareil', () async {
      final container = containerWith(
        FakeUpdateCheckEnvironment(installed: 94, latest: latestJson(android: 95, ios: 90)),
      );
      expect((await container.read(availableUpdateProvider.future))?.build, 95);
    });

    test('ne vérifie rien sans store (bureau, debug)', () async {
      final environment = FakeUpdateCheckEnvironment(platform: null, installed: 94, latest: latestJson(android: 95));
      final container = containerWith(environment);
      expect(await container.read(availableUpdateProvider.future), isNull);
      expect(environment.fetches, 0);
    });

    test('hors ligne : rien à proposer, sans erreur', () async {
      final container = containerWith(FakeUpdateCheckEnvironment(installed: 94, latest: null));
      expect(await container.read(availableUpdateProvider.future), isNull);
    });

    test('dismiss retient le build écarté et ne le repropose plus', () async {
      final environment = FakeUpdateCheckEnvironment(installed: 94, latest: latestJson(android: 95));
      final container = containerWith(environment);
      await container.read(availableUpdateProvider.future);

      await container.read(availableUpdateProvider.notifier).dismiss();

      expect(container.read(availableUpdateProvider).value, isNull);
      expect(environment.dismissed, 95);
      container.invalidate(availableUpdateProvider);
      expect(await container.read(availableUpdateProvider.future), isNull);
    });
  });
}
