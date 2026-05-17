import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';

/// Pretty-printed, colored console logger for **debug builds only**.
///
/// Uses the `logger` package to render:
/// - Boxed output with clear visual separation
/// - Color-coded levels (info = blue, warning = yellow, error = red)
/// - Formatted stack traces with method names
///
/// All output is suppressed in release/profile builds.
class DebugLogger implements AppLogger {
  final Logger _logger;

  DebugLogger()
      : _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 3,
            errorMethodCount: 8,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
          ),
          // Only log in debug mode. In release, this logger is silent.
          level: kDebugMode ? Level.trace : Level.off,
        );

  @override
  void info(String message, {String? tag}) {
    _logger.i(_format(message, tag));
  }

  @override
  void warning(String message, {String? tag}) {
    _logger.w(_format(message, tag));
  }

  @override
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _logger.e(_format(message, tag), error: error, stackTrace: stackTrace);
  }

  /// Prepends the contextual tag if provided: `[AUTH] Login failed`
  String _format(String message, String? tag) {
    if (tag != null) return '[$tag] $message';
    return message;
  }
}
