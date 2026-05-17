/// {@template app_logger}
/// Abstract interface for application logging.
///
/// This contract enables **Dependency Inversion**: the app codes against
/// [AppLogger], and the concrete implementation is injected at startup.
///
/// - In **debug** builds → [DebugLogger] (colored console output via `logger`)
/// - In **release** builds → [CrashlyticsLogger] (sends errors to Firebase Crashlytics)
///
/// Usage:
/// ```dart
/// // Via Riverpod
/// final log = ref.read(appLoggerProvider);
/// log.info('Pond created', tag: 'POND');
/// log.error('Failed to save', error: e, stackTrace: st, tag: 'DATABASE');
/// ```
/// {@endtemplate}
abstract class AppLogger {
  /// Logs an informational message. Suppressed in release builds.
  void info(String message, {String? tag});

  /// Logs a warning message. Suppressed in release builds.
  void warning(String message, {String? tag});

  /// Logs an error. In release builds, this is forwarded to Crashlytics.
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  });
}
