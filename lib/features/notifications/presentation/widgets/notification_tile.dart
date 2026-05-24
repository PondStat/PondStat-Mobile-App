import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';

class NotificationTile extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onToggleRead,
    required this.onDelete,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  IconData _getIconData(NotificationModel n) {
    final lowerTitle = n.title.toLowerCase();
    final lowerBody = n.body.toLowerCase();
    if (lowerTitle.contains('alert') ||
        lowerTitle.contains('warning') ||
        lowerBody.contains('alert') ||
        lowerBody.contains('warning')) {
      return Icons.warning_amber_rounded;
    } else if (lowerTitle.contains('error') ||
        lowerTitle.contains('fail') ||
        lowerBody.contains('error') ||
        lowerBody.contains('fail')) {
      return Icons.error_outline_rounded;
    } else if (lowerTitle.contains('success') ||
        lowerBody.contains('success')) {
      return Icons.check_circle_outline_rounded;
    }
    return Icons.info_outline_rounded;
  }

  Color _getIconColor(NotificationModel n, ColorScheme colorScheme) {
    final lowerTitle = n.title.toLowerCase();
    final lowerBody = n.body.toLowerCase();
    if (lowerTitle.contains('alert') ||
        lowerTitle.contains('warning') ||
        lowerBody.contains('alert') ||
        lowerBody.contains('warning')) {
      return Colors.orange;
    } else if (lowerTitle.contains('error') ||
        lowerTitle.contains('fail') ||
        lowerBody.contains('error') ||
        lowerBody.contains('fail')) {
      return colorScheme.error;
    } else if (lowerTitle.contains('success') ||
        lowerBody.contains('success')) {
      return Colors.green;
    }
    return colorScheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dynamicIcon = _getIconData(widget.notification);
    final dynamicColor = _getIconColor(widget.notification, colorScheme);
    final isRead = widget.notification.isRead;

    return Dismissible(
      key: Key(widget.notification.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isRead
                  ? Icons.mark_as_unread_rounded
                  : Icons.mark_email_read_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              isRead ? 'Mark Unread' : 'Mark Read',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.delete_outline_rounded,
              color: colorScheme.onErrorContainer,
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          widget.onToggleRead();
          return false; // Don't dismiss, just toggle
        }
        return true; // Proceed with deletion
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          HapticFeedback.mediumImpact();
          widget.onDelete();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isRead
                ? colorScheme.surface
                : colorScheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                  : colorScheme.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isRead
                          ? colorScheme.surfaceContainerHighest
                          : dynamicColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      dynamicIcon,
                      color: isRead
                          ? colorScheme.onSurfaceVariant
                          : dynamicColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                                child: Text(widget.notification.title),
                              ),
                            ),
                            Text(
                              _formatTimestamp(widget.notification.timestamp),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                          child: Text(widget.notification.body),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isRead ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Container(
                      margin: const EdgeInsets.only(left: 8, top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('h:mm a').format(timestamp);
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}
