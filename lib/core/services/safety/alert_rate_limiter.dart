import 'package:clock/clock.dart';
import 'alert_types.dart';

class AlertRateLimiter {
  /// Map of [cacheKey] to [DateTime] indicating when it last fired.
  final Map<String, DateTime> _lastAlerts = {};
  final Duration cooldownDuration;

  AlertRateLimiter({this.cooldownDuration = const Duration(hours: 1)});

  /// Generates a unique key for an alert condition.
  String _generateKey(String pondId, String parameterLabel, AlertTier tier) {
    return '${pondId}_${parameterLabel}_${tier.name}';
  }

  /// Checks if an alert should be allowed to fire.
  /// If it returns true, the alert is allowed and its timestamp is recorded.
  bool shouldAllowAlert(String pondId, String parameterLabel, AlertTier tier) {
    final key = _generateKey(pondId, parameterLabel, tier);
    final now = clock.now();

    if (_lastAlerts.containsKey(key)) {
      final lastFired = _lastAlerts[key]!;
      if (now.difference(lastFired) < cooldownDuration) {
        return false; // Still in cooldown
      }
    }

    // Allow and record
    _lastAlerts[key] = now;
    return true;
  }

  /// Clears the rate limiter state (useful for testing or manual reset).
  void clear() {
    _lastAlerts.clear();
  }
}
