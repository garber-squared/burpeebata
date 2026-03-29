import 'package:flutter_test/flutter_test.dart';
import 'package:burpeebata/services/dnd_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DndService', () {
    late DndService dndService;

    setUp(() {
      // Get the singleton instance
      dndService = DndService();
    });

    group('singleton pattern', () {
      test('returns same instance on multiple calls', () {
        final instance1 = DndService();
        final instance2 = DndService();

        expect(identical(instance1, instance2), isTrue);
      });
    });

    group('isSupported', () {
      test('returns false on non-Android platforms in test environment', () {
        // In Flutter test environment, Platform.isAndroid returns false
        // and kIsWeb is false, but the test environment doesn't match Android
        // The service should handle this gracefully
        expect(dndService.isSupported, isFalse);
      });
    });

    group('hasPermission', () {
      test('returns false when platform is not supported', () async {
        // On non-Android platforms, hasPermission should return false
        final hasPermission = await dndService.hasPermission();
        expect(hasPermission, isFalse);
      });
    });

    group('isDndEnabled', () {
      test('returns false when platform is not supported', () async {
        // On non-Android platforms, isDndEnabled should return false
        final isEnabled = await dndService.isDndEnabled();
        expect(isEnabled, isFalse);
      });
    });

    group('enableDnd', () {
      test('returns false when platform is not supported', () async {
        // On non-Android platforms, enableDnd should return false
        final result = await dndService.enableDnd();
        expect(result, isFalse);
      });
    });

    group('restoreDnd', () {
      test('completes without error when platform is not supported', () async {
        // On non-Android platforms, restoreDnd should complete without error
        await expectLater(
          dndService.restoreDnd(),
          completes,
        );
      });
    });

    group('requestPermission', () {
      test('completes without error when platform is not supported', () async {
        // On non-Android platforms, requestPermission should complete without error
        await expectLater(
          dndService.requestPermission(),
          completes,
        );
      });
    });
  });
}
