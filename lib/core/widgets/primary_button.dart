import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<BoxShadow>? customShadow;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width = double.infinity,
    this.backgroundColor,
    this.foregroundColor,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final disabledForegroundColor = isDark
        ? Colors.white38
        : Colors.grey.shade500;
    final currentForegroundColor = (onPressed == null || isLoading)
        ? disabledForegroundColor
        : (foregroundColor ?? Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null && !isLoading
            ? (customShadow ?? [
                BoxShadow(
                  color: (backgroundColor ?? theme.colorScheme.primary).withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ])
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: foregroundColor ?? Colors.white,
          disabledBackgroundColor: isDark
              ? Colors.white12
              : Colors.grey.shade300,
          disabledForegroundColor: disabledForegroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isLoading
            ? null
            : () {
                if (onPressed != null) {
                  HapticFeedback.mediumImpact();
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
                      color: currentForegroundColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
