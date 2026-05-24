import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BouncyMenuButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isDestructive;
  final VoidCallback onTap;

  const BouncyMenuButton({
    super.key,
    required this.icon,
    required this.text,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<BouncyMenuButton> createState() => _BouncyMenuButtonState();
}

class _BouncyMenuButtonState extends State<BouncyMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            widget.onTap();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color itemColor = widget.isDestructive
        ? Colors.red.shade600
        : theme.colorScheme.onSurface;
    final Color iconBgColor = widget.isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : theme.colorScheme.surfaceContainerHighest;
    final Color iconColor = widget.isDestructive
        ? Colors.red.shade600
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(16),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Semantics(
          button: true,
          label: widget.text,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: itemColor,
                    ),
                  ),
                ),
                if (!widget.isDestructive)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.5,
                    ),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
