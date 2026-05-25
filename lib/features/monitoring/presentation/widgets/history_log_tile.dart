import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryLogTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const HistoryLogTile({
    super.key,
    required this.data,
  });

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getActionMessage(Map<String, dynamic> data) {
    final action = data['action'] ?? 'unknown';
    final parameter = data['parameter'] ?? 'Unknown';
    final editor = data['editorName'] ?? 'Unknown';

    switch (action) {
      case 'create':
        return '$editor recorded parameters for $parameter';
      case 'growth_create':
        return '$editor recorded growth sampling for $parameter';
      case 'update':
        return '$editor updated parameters for $parameter';
      case 'growth_update':
        return '$editor updated growth sampling for $parameter';
      case 'delete':
        return '$editor deleted parameter record for $parameter';
      case 'clear_inputs':
        return '$editor cleared parameter inputs for $parameter';
      case 'alert':
        final tier = data['after']?['tier'] ?? 'warning';
        return '$parameter ${tier.toLowerCase()} alert triggered';
      default:
        return '$editor performed action on $parameter';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;

    final before = data['before'] ?? {};
    final after = data['after'] ?? {};
    String action = data['action'] ?? 'unknown';

    if (action == 'unknown') {
      if (data['before'] == null && data['after'] != null) {
        action = 'create';
      } else if (data['before'] != null && data['after'] == null) {
        action = 'delete';
      } else {
        action = 'update';
      }
    }

    final ts = data['editedAt'] as Timestamp?;
    final date = ts?.toDate();

    Color actionColor;
    IconData actionIcon;
    String actionLabel;

    if (action == 'delete') {
      actionColor = Colors.red;
      actionIcon = Icons.remove_circle_rounded;
      actionLabel = "DELETED";
    } else if (action == 'create') {
      actionColor = Colors.green;
      actionIcon = Icons.add_circle_rounded;
      actionLabel = "RECORDED";
    } else if (action == 'growth_create') {
      actionColor = Colors.teal;
      actionIcon = Icons.trending_up_rounded;
      actionLabel = "GROWTH LOG";
    } else if (action == 'growth_update') {
      actionColor = Colors.purple;
      actionIcon = Icons.update_rounded;
      actionLabel = "GROWTH EDIT";
    } else if (action == 'clear_inputs') {
      actionColor = Colors.orange;
      actionIcon = Icons.clear_all_rounded;
      actionLabel = "CLEARED";
    } else if (action == 'alert') {
      final tier = data['after']?['tier'] ?? 'warning';
      actionColor = tier == 'critical' ? Colors.red.shade700 : Colors.amber.shade700;
      actionIcon = tier == 'critical' ? Icons.warning_rounded : Icons.warning_amber_rounded;
      actionLabel = tier.toUpperCase();
    } else {
      actionColor = Colors.blue;
      actionIcon = Icons.edit_rounded;
      actionLabel = "EDITED";
    }

    final message = _getActionMessage(data);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border(
          left: BorderSide(color: actionColor, width: 6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: onSurface,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: actionColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        actionIcon,
                        size: 11,
                        color: actionColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: actionColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.layers_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  data['parameter'] ?? 'Parameter',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  date != null ? _formatRelativeTime(date) : '',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (action == 'update' || action == 'growth_update') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Was: ",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "${before['value'] ?? '-'}",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Now: ",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "${after['value'] ?? '-'}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (action == 'create' || action == 'growth_create') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Recorded Value: ",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "${after['value'] ?? '-'}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (action == 'alert') ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: actionColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['after']?['title'] ?? 'Alert triggered',
                      style: TextStyle(
                        color: actionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['after']?['body'] ?? 'Parameter value outside safe ranges.',
                      style: TextStyle(
                        color: actionColor.withValues(alpha: 0.8),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
