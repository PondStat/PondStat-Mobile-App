import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';

/// Production logger that forwards **errors** to Firebase Crashlytics.
///
/// - [info] and [warning] are silently discarded in production
///   (no console noise, no Crashlytics cost).
/// - [error] logs are recorded as non-fatal exceptions in Crashlytics
///   so the team can triage real-world crashes from the Firebase console.
///
/// The contextual [tag] is forwarded as a Crashlytics custom key,
/// enabling filtering by feature domain (e.g., "AUTH", "DATABASE").
class CrashlyticsLogger implements AppLogger {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsLogger({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  void info(String message, {String? tag}) {
    // Intentionally silent in production.
  }

  @override
  void warning(String message, {String? tag}) {
    // Intentionally silent in production.
    // If you want warnings in Crashlytics breadcrumbs, uncomment:
    // _crashlytics.log('[WARN${tag != null ? ':$tag' : ''}] $message');
  }

  @override
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    // Set the domain tag as a custom key for filtering in the Crashlytics dashboard.
    if (tag != null) {
      _crashlytics.setCustomKey('error_domain', tag);
    }

    // Log the human-readable message as a breadcrumb.
    _crashlytics.log(tag != null ? '[$tag] $message' : message);

    // Record the error as a non-fatal exception.
    if (error is Exception || error is Error) {
      _crashlytics.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    } else if (error != null) {
      // For non-Exception/Error types (e.g., String), wrap them.
      _crashlytics.recordError(
        Exception('$error'),
        stackTrace,
        reason: message,
        fatal: false,
      );
    } else {
      // No error object — just record the message.
      _crashlytics.recordError(
        Exception(message),
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }
}
