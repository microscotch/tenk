import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:le10000/ui/full_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  test('sur Android, le plein écran est immersif et « collant » : les barres se recachent seules', () async {
    await applyFullScreen(platform: TargetPlatform.android);

    final call = calls.singleWhere((c) => c.method == 'SystemChrome.setEnabledSystemUIMode');
    expect(call.arguments, 'SystemUiMode.immersiveSticky');
  });

  test('ailleurs qu\'Android, rien ne change : iOS garde sa barre d\'état', () async {
    for (final platform in [TargetPlatform.iOS, TargetPlatform.linux, TargetPlatform.macOS, TargetPlatform.windows]) {
      await applyFullScreen(platform: platform);
    }

    expect(calls.where((c) => c.method == 'SystemChrome.setEnabledSystemUIMode'), isEmpty);
  });
}
