import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';

/// MANUAL TESTING FLOW:
/// 1. Create a measurement with an alert via the Cloud Function trigger (or manual Firestore entry).
/// 2. Observe the notification badge increment on the dashboard.
/// 3. Open the inbox and see the new alert entry.
/// 4. Tap the notification to mark it read – the dot should disappear and the badge count drop.
/// 5. Swipe the notification to delete it – it should disappear from the list.
///
/// NOTE: If notifications don't appear, check Firestore security rules for:
/// users/{uid}/notifications subcollection.

class NotificationsInboxPage extends StatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  State<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends State<NotificationsInboxPage> {
  final repository = NotificationsRepository();
  Key _streamKey = UniqueKey();
  bool _showUnreadOnly = false;

  void _retry() {
    setState(() {
      _streamKey = UniqueKey();
    });
  }

  List<dynamic> _groupNotifications(List<NotificationModel> raw) {
    final filtered = _showUnreadOnly
        ? raw.where((n) => !n.isRead).toList()
        : raw;
    if (filtered.isEmpty) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastWeek = today.subtract(const Duration(days: 7));

    final Map<String, List<NotificationModel>> groups = {
      'Today': [],
      'Yesterday': [],
      'Last 7 Days': [],
      'Older': [],
    };

    for (final n in filtered) {
      final date = DateTime(
        n.timestamp.year,
        n.timestamp.month,
        n.timestamp.day,
      );
      if (date == today) {
        groups['Today']!.add(n);
      } else if (date == yesterday) {
        groups['Yesterday']!.add(n);
      } else if (date.isAfter(lastWeek)) {
        groups['Last 7 Days']!.add(n);
      } else {
        groups['Older']!.add(n);
      }
    }

    final List<dynamic> result = [];
    groups.forEach((title, items) {
      if (items.isNotEmpty) {
        result.add(title);
        result.addAll(items);
      }
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(
              _showUnreadOnly
                  ? Icons.filter_list_off_rounded
                  : Icons.filter_list_rounded,
            ),
            tooltip: _showUnreadOnly ? 'Show all' : 'Show unread',
            onPressed: () => setState(() => _showUnreadOnly = !_showUnreadOnly),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'markAllRead') {
                repository.markAllAsRead();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'markAllRead',
                child: Text('Mark all as read'),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _retry();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<List<NotificationModel>>(
          key: _streamKey,
          stream: repository.getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load notifications',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _retry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final rawNotifications = snapshot.data ?? [];
            final groupedItems = _groupNotifications(rawNotifications);

            if (groupedItems.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: EmptyStateCard(
                        icon: _showUnreadOnly
                            ? Icons.mark_email_read_rounded
                            : Icons.notifications_none_rounded,
                        title: _showUnreadOnly
                            ? 'No unread notifications'
                            : 'No notifications yet',
                        description: _showUnreadOnly
                            ? 'You\'re all caught up!'
                            : 'Alerts and updates will appear here.',
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: groupedItems.length,
              itemBuilder: (context, index) {
                final item = groupedItems[index];

                if (item is String) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24, bottom: 8, left: 4),
                    child: Text(
                      item,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  );
                }

                final n = item as NotificationModel;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _NotificationTile(
                    notification: n,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      if (!n.isRead) {
                        await repository.markAsRead(n.id);
                      }
                    },
                    onToggleRead: () =>
                        repository.updateReadStatus(n.id, !n.isRead),
                    onDelete: () => repository.deleteNotification(n.id),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onToggleRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          notification.isRead
              ? Icons.mark_as_unread_rounded
              : Icons.mark_email_read_rounded,
          color: colorScheme.onSecondaryContainer,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          HapticFeedback.mediumImpact();
          onToggleRead();
          return false; // Don't dismiss, just toggle
        }
        return true; // Proceed with deletion
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: notification.isRead
                ? colorScheme.outlineVariant.withValues(alpha: 0.5)
                : colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        color: notification.isRead
            ? colorScheme.surface
            : colorScheme.primaryContainer.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notification.isRead
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: notification.isRead
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
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
                            child: Text(
                              notification.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: notification.isRead
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
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
