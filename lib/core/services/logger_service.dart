import 'package:flutter/foundation.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/debug_logger.dart';
import 'package:pondstat/core/services/logging/crashlytics_logger.dart';

/// {@template logger_service}
/// **DEPRECATED**: Use [AppLogger] via `ref.read(appLoggerProvider)` instead.
///
/// This static shim exists only for contexts where Riverpod is not available
/// (e.g., top-level background isolate handlers like `_firebaseMessagingBackgroundHandler`).
///
/// New code should always inject [AppLogger] via the provider.
/// {@endtemplate}
@Deprecated('Use appLoggerProvider instead. See class docstring.')
class LoggerService {
  static final AppLogger _instance =
      kDebugMode ? DebugLogger() : CrashlyticsLogger();

  /// Logs an informational message.
  static void info(String message, {String? tag}) {
    _instance.info(message, tag: tag);
  }

  /// Logs a warning message.
  static void warning(String message, {String? tag}) {
    _instance.warning(message, tag: tag);
  }

  /// Logs an error. In release builds, forwarded to Firebase Crashlytics.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _instance.error(message, error: error, stackTrace: stackTrace);
  }
}
