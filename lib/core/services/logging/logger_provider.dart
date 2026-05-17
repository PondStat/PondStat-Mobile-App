import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/debug_logger.dart';
import 'package:pondstat/core/services/logging/crashlytics_logger.dart';

/// A composite logger that fans out to multiple [AppLogger] backends.
///
/// In **debug** builds: logs go to [DebugLogger] (pretty console) only.
/// In **release** builds: logs go to [CrashlyticsLogger] (Firebase) only.
///
/// If you ever need both simultaneously (e.g., during a staging build),
/// simply pass both into the [loggers] list.
class CompositeLogger implements AppLogger {
  final List<AppLogger> loggers;

  CompositeLogger(this.loggers);

  @override
  void info(String message, {String? tag}) {
    for (final logger in loggers) {
      logger.info(message, tag: tag);
    }
  }

  @override
  void warning(String message, {String? tag}) {
    for (final logger in loggers) {
      logger.warning(message, tag: tag);
    }
  }

  @override
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    for (final logger in loggers) {
      logger.error(message, error: error, stackTrace: stackTrace, tag: tag);
    }
  }
}

/// Provides the app-wide [AppLogger] instance.
///
/// - **Debug**: [DebugLogger] (pretty, colored console output)
/// - **Release**: [CrashlyticsLogger] (errors forwarded to Firebase Crashlytics)
///
/// Usage:
/// ```dart
/// final log = ref.read(appLoggerProvider);
/// log.info('Pond created successfully', tag: 'POND');
/// log.error('Save failed', error: e, stackTrace: st, tag: 'DATABASE');
/// ```
final appLoggerProvider = Provider<AppLogger>((ref) {
  if (kDebugMode) {
    return DebugLogger();
  }
  return CrashlyticsLogger();
});
