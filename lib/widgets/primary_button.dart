import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed != null && !isLoading
            ? [
                BoxShadow(
                  color: isSuccess
                      ? Colors.green.withValues(alpha: 0.3)
                      : theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSuccess ? Colors.green : theme.colorScheme.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isDark
              ? Colors.white12
              : Colors.grey.shade300,
          disabledForegroundColor: isDark
              ? Colors.white38
              : Colors.grey.shade500,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: (isLoading || isSuccess)
            ? null
            : () {
                if (onPressed != null) {
                  HapticFeedback.mediumImpact();
                  onPressed!();
                }
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isSuccess
                  ? const Icon(
                      Icons.check_circle_rounded,
                      size: 24,
                      key: ValueKey('success'),
                    )
                  : isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : icon != null
                  ? Icon(icon, size: 20, key: const ValueKey('icon'))
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            if (icon != null || isLoading || isSuccess)
              const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isSuccess ? 'Success' : text,
                key: ValueKey(isSuccess ? 'success_text' : 'normal_text'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
