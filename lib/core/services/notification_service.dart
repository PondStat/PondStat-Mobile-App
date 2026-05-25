import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/core/services/safety/app_notifier.dart';
import 'package:pondstat/core/services/logger_service.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/core/services/notification_types.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ignore: deprecated_member_use
  LoggerService.info(
    'Handling a background message: ${message.messageId}',
    tag: 'FCM',
  );
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(appLoggerProvider), ref);
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
class NotificationService implements AppNotifier {
  final AppLogger _logger;
  final Ref _ref;

  NotificationService(this._logger, this._ref);

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  bool _initialized = false;

  /// GoRouter instance, injected after the router is created.
  /// Used for notification tap deep linking.
  GoRouter? _router;
  set router(GoRouter router) => _router = router;

  // ─── Token Stream (SRP: expose, don't persist) ──────────────────────

  /// Stream of FCM token refreshes. Consumed by [AuthRepository] to persist
  /// the token to Firestore — keeping database concerns out of this class.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  // ─── Initialization ─────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground notification handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final route = message.data['route'] as String?;
        _showLocalNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          payload: route,
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

  /// Gets the FCM device token.
  ///
  /// **Do NOT call requestPermission here.** This is decoupled to allow silent
  /// token synchronization on startup without JIT permission bypass.
  Future<String?> getDeviceToken() async {
    if (kIsWeb) return null;
    try {
      return await _fcm.getToken();
    } catch (e, stackTrace) {
      _logger.error('Error getting device token', error: e, stackTrace: stackTrace, tag: 'FCM');
      return null;
    }
  }

  // ─── Notification Action Handler ────────────────────────────────────

  void _onNotificationTapped(NotificationResponse response) {
    final actionId = response.actionId;
    final payload = response.payload;

    if (actionId == NotificationAction.acknowledge.id) {
      if (payload != null && payload.isNotEmpty) {
        _acknowledgeAlert(payload);
      }
      return;
    }

    if (actionId == NotificationAction.viewChart.id || actionId == null) {
      // Deep-link to the pond's page using the route payload
      if (payload != null && payload.isNotEmpty && _router != null) {
        _logger.info('Deep linking to: $payload', tag: 'NOTIFICATION');
        _router!.push(payload);
      }
      return;
    }
  }

  // ─── Generic Local Notification ─────────────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
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
      payload: payload,
    );
  }

  // ─── Parameter Alert (Critical — High Importance) ───────────────────

  /// Shows a critical parameter alert with **notification grouping** by pond
  /// and **actionable buttons** on the lock screen.
  ///
  /// - Importance: **High** (heads-up, vibrates, LED)
  /// - Grouped by [pondId] so multiple alerts for the same pond collapse
  /// - Actions: "Acknowledge" and "View Chart" buttons
  @override
  Future<void> dispatchParameterAlert({
    required String pondId,
    required String pondName,
    required String parameter,
    required double value,
    required String unit,
    required String title,
    required String body,
    required String routePayload,
    required bool isCritical,
  }) async {

    // ── Notification Grouping: collapse by pondId ──────────────────────
    final String groupKey = 'pond_alerts_$pondId';

    final androidDetails = AndroidNotificationDetails(
      NotificationChannel.parameterAlerts.id,
      NotificationChannel.parameterAlerts.name,
      channelDescription: NotificationChannel.parameterAlerts.description,
      importance: isCritical ? Importance.high : Importance.defaultImportance,
      priority: isCritical ? Priority.high : Priority.defaultPriority,
      ticker: 'ticker',
      color: const Color(0xFF0A74DA),
      ledColor: isCritical ? const Color(0xFFD32F2F) : const Color(0xFFFFA726),
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
      payload: routePayload,
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

  Future<void> _acknowledgeAlert(String payload) async {
    try {
      final uri = Uri.tryParse(payload);
      if (uri == null) return;
      final pondId = uri.queryParameters['pondId'];
      final parameter = uri.queryParameters['parameter'];
      if (pondId == null || parameter == null) return;

      final baseRef = _ref.read(appBaseRefProvider);
      final measurementsCollection = baseRef.collection('measurements');

      // Find the latest measurement with this pondId and parameter
      final querySnapshot = await measurementsCollection
          .where('pondId', isEqualTo: pondId)
          .where('parameter', isEqualTo: parameter)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.warning(
          'No measurement found to acknowledge alert for pond $pondId, parameter $parameter',
          tag: 'NOTIFICATION',
        );
        return;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      if (data['alert'] != null) {
        await doc.reference.update({
          'alert.isAcknowledged': true,
          'alert.acknowledgedAt': FieldValue.serverTimestamp(),
          'alert.acknowledgedBy': _ref.read(firebaseAuthProvider).currentUser?.uid,
        });
        _logger.info(
          'Successfully acknowledged alert for doc ${doc.id}',
          tag: 'NOTIFICATION',
        );
      } else {
        _logger.warning(
          'Measurement ${doc.id} does not have an alert field',
          tag: 'NOTIFICATION',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Error acknowledging alert in Firestore',
        error: e,
        stackTrace: stackTrace,
        tag: 'NOTIFICATION',
      );
    }
  }

  Future<void> scheduleShiftReminders({
    required String pondId,
    required String pondName,
    required String userId,
    required Map<String, dynamic> schedule,
  }) async {
    if (kIsWeb) return;

    final List<String> daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final androidDetails = AndroidNotificationDetails(
      NotificationChannel.shiftReminders.id,
      NotificationChannel.shiftReminders.name,
      channelDescription: NotificationChannel.shiftReminders.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 1. Cancel previous notifications for this pond/user to avoid overlap
    final baseId = pondId.hashCode.abs() % 10000;
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      for (int shiftIndex = 0; shiftIndex < 2; shiftIndex++) {
        final id = baseId * 100 + dayIndex * 10 + shiftIndex;
        await _localNotifications.cancel(id);
      }
    }

    // 2. Schedule new ones based on the user's active shifts
    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final dayName = daysOfWeek[dayIndex];
      if (!schedule.containsKey(dayName)) continue;

      final dayMap = schedule[dayName];
      if (dayMap is! Map) continue;

      final bool morning = dayMap['morning'] == true;
      final bool afternoon = dayMap['afternoon'] == true;

      final targetDayOfWeek = dayIndex + 1;

      if (morning) {
        final id = baseId * 100 + dayIndex * 10 + 0;
        final scheduledDate = _nextInstanceOfDayOfWeekAndTime(targetDayOfWeek, 8, 0);
        final String dueParams = _getDueParametersMessage(dayName);

        await _localNotifications.zonedSchedule(
          id,
          '🌅 Shift Reminder: Morning',
          'Your shift for $pondName is scheduled. Due: $dueParams',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '/pond/$pondId',
        );
      }

      if (afternoon) {
        final id = baseId * 100 + dayIndex * 10 + 1;
        final scheduledDate = _nextInstanceOfDayOfWeekAndTime(targetDayOfWeek, 16, 0);
        final String dueParams = _getDueParametersMessage(dayName);

        await _localNotifications.zonedSchedule(
          id,
          '🌇 Shift Reminder: Afternoon',
          'Your shift for $pondName is scheduled. Due: $dueParams',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: '/pond/$pondId',
        );
      }
    }
  }

  String _getDueParametersMessage(String dayName) {
    if (dayName == 'Monday') {
      return 'Daily parameters & Weekly Biological parameters (Phytoplankton, etc.)';
    } else if (dayName == 'Wednesday') {
      return 'Daily parameters & Biweekly Chemical parameters (Dissolved Oxygen, Ammonia, Nitrite, etc.)';
    } else {
      return 'Daily parameters (pH, Temp, Salinity, Transparency)';
    }
  }

  tz.TZDateTime _nextInstanceOfDayOfWeekAndTime(int targetDayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    while (scheduledDate.isBefore(now) || scheduledDate.weekday != targetDayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
