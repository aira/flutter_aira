import 'package:flutter_aira/src/throttler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Throttler tests', () {
    test('First call is never throttled', () async {
      Throttler throttler = Throttler(delay: 50);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(throttler.shouldThrottle, isFalse); // first call is always false
    });

    test('First call is never throttled even when called long after creation',
        () async {
      Throttler throttler = Throttler(delay: 50);
      await Future.delayed(const Duration(milliseconds: 75));
      expect(throttler.shouldThrottle, isFalse); // first call is always false
    });

    test('Should Throttle with expected delay', () async {
      Throttler throttler = Throttler(delay: 50);
      expect(throttler.shouldThrottle, isFalse); // first call is always false
      await Future.delayed(const Duration(milliseconds: 55));
      expect(throttler.shouldThrottle, isFalse);
      expect(throttler.shouldThrottle, isTrue); // second call is throttled
      expect(throttler.shouldThrottle, isTrue);
      await Future.delayed(const Duration(milliseconds: 30));
      expect(throttler.shouldThrottle, isTrue);
      await Future.delayed(const Duration(milliseconds: 21));
      expect(throttler.shouldThrottle, isFalse);
      expect(throttler.shouldThrottle, isTrue); // second call is throttled
    });
  });
}
