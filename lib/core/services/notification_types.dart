/// Type-safe notification channel configurations and enums.
///
/// Centralizes all magic strings to prevent silent failures from typos.
library;

// ─── Alert Status ───────────────────────────────────────────────────────

/// Whether a parameter reading is above or below its safe range.
enum AlertStatus {
  below('below', 'LOW'),
  above('above', 'HIGH');

  const AlertStatus(this.value, this.label);

  /// Raw string value (for serialization/backwards compat).
  final String value;

  /// Human-readable label for notification text.
  final String label;
}

// ─── Notification Channels ──────────────────────────────────────────────

/// Android notification channel configurations.
///
/// Each enum value maps to exactly one Android notification channel.
/// Adding a new channel? Add it here — never hardcode channel IDs.
enum NotificationChannel {
  /// Foreground FCM push notifications.
  fcmAlerts(
    id: 'fcm_alerts',
    name: 'Push Notifications',
    description: 'Notifications received via FCM',
  ),

  /// Critical parameter alerts (high importance — buzzes, heads-up).
  parameterAlerts(
    id: 'pond_parameter_alerts',
    name: 'Pond Parameter Alerts',
    description: 'Alerts when pond parameters are out of safe range',
  ),

  /// Daily health summaries (default importance — silent badge).
  healthSummary(
    id: 'pond_health_summary',
    name: 'Pond Health Summary',
    description: 'Daily summary of pond health status',
  ),

  /// Scheduled shift reminders.
  shiftReminders(
    id: 'pond_shift_reminders',
    name: 'Shift Reminders',
    description: 'Reminders for your assigned shifts and due parameters',
  ),

  /// Proactive weather alerts.
  weatherAlerts(
    id: 'pond_weather_alerts',
    name: 'Weather Alerts',
    description: 'Proactive warnings and recommendations based on weather forecast',
  );

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

// ─── Notification Actions ───────────────────────────────────────────────

/// Action button IDs shown on the lock screen for parameter alerts.
enum NotificationAction {
  acknowledge('action_acknowledge', 'Acknowledge'),
  viewChart('action_view_chart', 'View Chart');

  const NotificationAction(this.id, this.label);

  final String id;
  final String label;
}
