import 'package:flutter/foundation.dart';

class LoggerService {
  /// Logs an informational message if the app is running in debug mode.
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO]: $message');
    }
  }

  /// Logs a warning message if the app is running in debug mode.
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING]: $message');
    }
  }

  /// Logs an error message and optional stacktrace if the app is running in debug mode.
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [ERROR]: $message');
      if (error != null) {
        debugPrint('Error Details: $error');
      }
      if (stackTrace != null) {
        debugPrint('Stacktrace: $stackTrace');
      }
    }
  }
}
