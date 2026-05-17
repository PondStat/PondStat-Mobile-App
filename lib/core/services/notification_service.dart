import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:pondstat/core/services/logger_service.dart';
import 'package:pondstat/core/services/notification_types.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: deprecated_member_use
  LoggerService.info(
    'Handling a background message: ${message.messageId}',
    tag: 'FCM',
  );
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Notification service responsible for local + FCM push notification display.
///
/// ## Architecture Notes
/// - **SRP**: This class does NOT write to Firestore. FCM token persistence
///   is handled by [AuthRepository] which listens to [onTokenRefresh].
/// - **Just-in-Time Permissions**: [initialize] no longer requests permissions.
///   Call [requestPermission] contextually (e.g., after onboarding, from settings).
/// - **Type Safety**: All channel IDs, action IDs, and alert statuses use enums
///   from [notification_types.dart] — no raw strings.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  // ─── Token Stream (SRP: expose, don't persist) ──────────────────────

  /// Stream of FCM token refreshes. Consumed by [AuthRepository] to persist
  /// the token to Firestore — keeping database concerns out of this class.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ─── Initialization ─────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });

    // ── Local Notifications Setup ──────────────────────────────────────
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const iosSettings = DarwinInitializationSettings(
      // JIT Permissions: Do NOT request here. Let the user grant when ready.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    // NOTE: requestPermission() is intentionally NOT called here.
    // Call it contextually from the UI after explaining value to the user.
  }

  // ─── Permission Handling (Just-in-Time) ─────────────────────────────

  /// Request notification permissions.
  ///
  /// **Do NOT call at app startup.** Instead, trigger this after the user
  /// has seen the app's value — e.g., after creating their first pond,
  /// or from a "Notification Settings" toggle.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  /// Gets the FCM device token (requests permission first if needed).
  Future<String?> getDeviceToken() async {
    if (kIsWeb) return null;
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      return await _fcm.getToken();
    } catch (e, stackTrace) {
      // ignore: deprecated_member_use
      LoggerService.error('Error getting device token', e, stackTrace);
      return null;
    }
  }

  // ─── Notification Action Handler ────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;

    if (actionId == NotificationAction.acknowledge.id) {
      // TODO: Mark the alert as acknowledged in Firestore
      return;
    }

    if (actionId == NotificationAction.viewChart.id) {
      // TODO: Deep-link to the pond's trends/chart page
      return;
    }

    // Default tap — app opens normally via the OS launcher.
  }

  // ─── Generic Local Notification ─────────────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      NotificationChannel.fcmAlerts.id,
      NotificationChannel.fcmAlerts.name,
      channelDescription: NotificationChannel.fcmAlerts.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // ─── Parameter Alert (Critical — High Importance) ───────────────────

  /// Shows a critical parameter alert with **notification grouping** by pond
  /// and **actionable buttons** on the lock screen.
  ///
  /// - Importance: **High** (heads-up, vibrates, LED)
  /// - Grouped by [pondId] so multiple alerts for the same pond collapse
  /// - Actions: "Acknowledge" and "View Chart" buttons
  Future<void> showParameterAlert({
    required String pondId,
    required String pondName,
    required String parameter,
    required double value,
    required String unit,
    required double minValue,
    required double maxValue,
    required AlertStatus status,
  }) async {
    final String title = '⚠️ $parameter Alert - $pondName';
    final String body =
        '$parameter is ${status.label}: $value $unit\nSafe range: $minValue - $maxValue $unit';

    // ── Notification Grouping: collapse by pondId ──────────────────────
    final String groupKey = 'pond_alerts_$pondId';

    final androidDetails = AndroidNotificationDetails(
      NotificationChannel.parameterAlerts.id,
      NotificationChannel.parameterAlerts.name,
      channelDescription: NotificationChannel.parameterAlerts.description,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      color: const Color(0xFF0A74DA),
      ledColor: const Color(0xFFFFA726),
      ledOnMs: 1000,
      ledOffMs: 500,
      // Grouping: all alerts for same pond collapse into one summary
      groupKey: groupKey,
      // Actionable buttons on the lock screen
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          NotificationAction.acknowledge.id,
          NotificationAction.acknowledge.label,
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          NotificationAction.viewChart.id,
          NotificationAction.viewChart.label,
          showsUserInterface: true,
        ),
      ],
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      // iOS groups by threadIdentifier
      threadIdentifier: groupKey,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the individual notification
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );

    // Show the group summary (collapses individual notifications)
    await _showGroupSummary(
      groupKey: groupKey,
      channelId: NotificationChannel.parameterAlerts.id,
      channelName: NotificationChannel.parameterAlerts.name,
      channelDescription: NotificationChannel.parameterAlerts.description,
      summaryTitle: '⚠️ Alerts - $pondName',
    );
  }

  // ─── Pond Health Summary (Digest — Default Importance) ──────────────

  /// Shows a daily health summary with **default** importance.
  ///
  /// Unlike [showParameterAlert], this does NOT buzz the phone or display
  /// as a heads-up notification. It appears silently in the notification tray.
  Future<void> showPondHealthSummary({
    required String pondName,
    required List<String> alerts,
  }) async {
    if (alerts.isEmpty) return;

    final String title = '📋 PondStat Summary - $pondName';
    final String body =
        alerts.take(2).join('\n') +
        (alerts.length > 2 ? '\n+${alerts.length - 2} more issues' : '');

    // Default importance: silent badge, no heads-up, no vibration
    final androidDetails = AndroidNotificationDetails(
      NotificationChannel.healthSummary.id,
      NotificationChannel.healthSummary.name,
      channelDescription: NotificationChannel.healthSummary.description,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false, // Silent for summaries
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  // ─── Group Summary Helper ───────────────────────────────────────────

  /// Creates an Android "inbox style" group summary notification.
  ///
  /// When multiple individual notifications share the same [groupKey],
  /// Android collapses them under this summary instead of spamming
  /// the notification tray with separate entries.
  Future<void> _showGroupSummary({
    required String groupKey,
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String summaryTitle,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      groupKey: groupKey,
      setAsGroupSummary: true,
      // Inbox style shows a summary of grouped notifications
      styleInformation: const InboxStyleInformation(
        [],
        contentTitle: 'Parameter Alerts',
        summaryText: 'Tap to view all alerts',
      ),
    );

    final details = NotificationDetails(android: androidDetails);

    // Use a stable ID derived from groupKey so the summary updates in-place
    await _localNotifications.show(
      groupKey.hashCode,
      summaryTitle,
      '',
      details,
    );
  }
}
