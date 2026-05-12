import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final disabledForegroundColor = isDark
        ? Colors.white38
        : Colors.grey.shade500;
    final disabledBackgroundColor = isDark
        ? Colors.white12
        : Colors.grey.shade200;
    final currentForegroundColor = (onPressed == null || isLoading)
        ? disabledForegroundColor
        : buttonColor;

    // Ghost border fix
    final currentBorderColor = (onPressed == null || isLoading)
        ? disabledForegroundColor.withValues(alpha: 0.2)
        : (isDark
              ? buttonColor.withValues(alpha: 0.2)
              : buttonColor.withValues(alpha: 0.15));

    return SizedBox(
      width: width,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: buttonColor,
          backgroundColor: isDark
              ? buttonColor.withValues(alpha: 0.1)
              : buttonColor.withValues(alpha: 0.08),
          disabledForegroundColor: disabledForegroundColor,
          disabledBackgroundColor: disabledBackgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: currentBorderColor, width: 1.5),
          ),
        ),
        onPressed: isLoading
            ? null
            : () {
                if (onPressed != null) {
                  HapticFeedback.lightImpact();
                  onPressed!();
                }
              },
        child: isLoading
            ? Semantics(
                label: 'Loading, please wait',
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: currentForegroundColor,
                    strokeWidth: 3,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20, color: currentForegroundColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: currentForegroundColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
