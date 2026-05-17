import 'package:flutter_test/flutter_test.dart';
import 'package:clock/clock.dart';
import 'package:pondstat/core/services/safety/alert_rate_limiter.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';

void main() {
  group('AlertRateLimiter', () {
    test('allows the first alert and records it', () {
      final limiter = AlertRateLimiter();
      expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isTrue);
    });

    test('blocks subsequent identical alerts within cooldown period', () {
      withClock(Clock.fixed(DateTime(2023, 1, 1, 12, 0, 0)), () {
        final limiter = AlertRateLimiter(cooldownDuration: const Duration(hours: 1));
        
        // First one allowed
        expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.critical), isTrue);
        
        // Second one immediately blocked
        expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.critical), isFalse);
      });
    });

    test('allows alert after cooldown expires', () {
      final startTime = DateTime(2023, 1, 1, 12, 0, 0);
      final limiter = AlertRateLimiter(cooldownDuration: const Duration(hours: 1));

      // Fire at 12:00
      withClock(Clock.fixed(startTime), () {
        expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isTrue);
      });

      // Try at 12:30 (blocked)
      withClock(Clock.fixed(startTime.add(const Duration(minutes: 30))), () {
        expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isFalse);
      });

      // Try at 13:01 (allowed)
      withClock(Clock.fixed(startTime.add(const Duration(minutes: 61))), () {
        expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isTrue);
      });
    });

    test('differentiates by pond, parameter, and tier', () {
      final limiter = AlertRateLimiter();
      
      expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isTrue);
      
      // Different pond
      expect(limiter.shouldAllowAlert('p2', 'pH', AlertTier.warning), isTrue);
      
      // Different parameter
      expect(limiter.shouldAllowAlert('p1', 'DO', AlertTier.warning), isTrue);
      
      // Different tier
      expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.critical), isTrue);
      
      // Same everything (blocked)
      expect(limiter.shouldAllowAlert('p1', 'pH', AlertTier.warning), isFalse);
    });
  });
}
