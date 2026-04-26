import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    _initialized = true;

    // Request permissions on initialization (Mobile only)
    await requestPermission();
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    final status = await Permission.notification.status;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> showParameterAlert({
    required String pondName,
    required String parameter,
    required double value,
    required String unit,
    required double minValue,
    required double maxValue,
    required String status, // 'below' or 'above'
  }) async {
    final String title = '⚠️ $parameter Alert - $pondName';
    final String body = status == 'below'
        ? '$parameter is LOW: $value $unit\nSafe range: $minValue - $maxValue $unit'
        : '$parameter is HIGH: $value $unit\nSafe range: $minValue - $maxValue $unit';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pond_parameter_alerts',
          'Pond Parameter Alerts',
          channelDescription:
              'Alerts when pond parameters are out of safe range',
          importance: Importance.high,
          priority: Priority.high,
          ticker: 'ticker',
          color: Color(0xFF0A74DA),
          ledColor: Color(0xFFFFA726),
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showPondHealthSummary({
    required String pondName,
    required List<String> alerts,
  }) async {
    if (alerts.isEmpty) return;

    final String title = '🚨 PondStat Alert - $pondName';
    final String body =
        alerts.take(2).join('\n') +
        (alerts.length > 2 ? '\n+${alerts.length - 2} more issues' : '');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'pond_health_summary',
          'Pond Health Summary',
          channelDescription: 'Daily summary of pond health status',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }
}
