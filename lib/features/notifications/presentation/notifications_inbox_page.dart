import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/notifications/presentation/widgets/notifications_shimmer.dart';
import 'package:pondstat/features/notifications/presentation/widgets/notification_tile.dart';

/// MANUAL TESTING FLOW:
/// 1. Create a measurement with an alert via the Cloud Function trigger (or manual Firestore entry).
/// 2. Observe the notification badge increment on the dashboard.
/// 3. Open the inbox and see the new alert entry.
/// 4. Tap the notification to mark it read – the dot should disappear and the badge count drop.
/// 5. Swipe the notification to delete it – it should disappear from the list.
///
/// NOTE: If notifications don't appear, check Firestore security rules for:
/// users/{uid}/notifications subcollection.

class NotificationsInboxPage extends ConsumerStatefulWidget {
  const NotificationsInboxPage({super.key});

  @override
  ConsumerState<NotificationsInboxPage> createState() => _NotificationsInboxPageState();
}

class _NotificationsInboxPageState extends ConsumerState<NotificationsInboxPage> {
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
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _showUnreadOnly = !_showUnreadOnly);
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(notificationsRepositoryProvider).markAllAsRead();
            },
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
          stream: ref.watch(notificationsRepositoryProvider).getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const NotificationsShimmer();
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
                        image: Icon(_showUnreadOnly
                            ? Icons.mark_email_read_rounded
                            : Icons.notifications_none_rounded),
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final n = item as NotificationModel;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: NotificationTile(
                    notification: n,
                    onTap: () async {
                      if (!n.isRead) {
                        await ref.read(notificationsRepositoryProvider).markAsRead(n.id);
                      }
                    },
                    onToggleRead: () =>
                        ref.read(notificationsRepositoryProvider).updateReadStatus(n.id, !n.isRead),
                    onDelete: () async {
                      await ref.read(notificationsRepositoryProvider).deleteNotification(n.id);
                      if (context.mounted) {
                        final shouldUndo = await SnackbarHelper.showUndoable(
                          context,
                          'Notification deleted',
                        );
                        if (shouldUndo) {
                          await ref
                              .read(notificationsRepositoryProvider)
                              .restoreNotification(n);
                          _retry();
                        }
                      }
                    },
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
