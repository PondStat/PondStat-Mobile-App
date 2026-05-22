import 'package:flutter/material.dart';
import 'package:pondstat/core/theme/app_metrics.dart';

class SnackbarHelper {
  SnackbarHelper._();

  /// Hides any currently visible SnackBar to prevent queue spam.
  static void _hideCurrent(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Base internal method for showing a themed SnackBar
  static void _showBase({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
  }) {
    _hideCurrent(context);

    // Provide a fallback in case AppMetrics isn't in the theme yet
    final radius = Theme.of(context).extension<AppMetrics>()?.radiusButton ?? 12.0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Displays a success SnackBar (e.g., successful save, sent email).
  static void showSuccess(BuildContext context, String message) {
    _showBase(
      context: context,
      message: message,
      backgroundColor: const Color(0xFF10B981), // Emerald 500
      foregroundColor: Colors.white,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Displays an error SnackBar (e.g., failed save, invalid input).
  static void showError(BuildContext context, String message) {
    _showBase(
      context: context,
      message: message,
      backgroundColor: const Color(0xFFEF4444), // Red 500
      foregroundColor: Colors.white,
      icon: Icons.error_rounded,
    );
  }

  /// Displays an info SnackBar (e.g., general neutral notifications).
  static void showInfo(BuildContext context, String message) {
    _showBase(
      context: context,
      message: message,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      icon: Icons.info_rounded,
    );
  }

  /// Displays an info SnackBar with an "Undo" action.
  /// Returns `true` if the user pressed Undo before the SnackBar dismissed.
  static Future<bool> showUndoable(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) async {
    _hideCurrent(context);

    final radius = Theme.of(context).extension<AppMetrics>()?.radiusButton ?? 12.0;
    bool undoPressed = false;

    final controller = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_rounded, color: Theme.of(context).colorScheme.onSurface, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            undoPressed = true;
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        duration: duration,
      ),
    );

    await controller.closed;
    return undoPressed;
  }
}
