import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final orangeText = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
    final orangeIcon = isDark ? Colors.orange.shade300 : Colors.orange.shade400;
    final greenIcon = isDark ? Colors.green.shade300 : Colors.green.shade400;

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        bool hasPendingWrites = snapshot.hasData
            ? snapshot.data!.metadata.hasPendingWrites
            : false;

        return Tooltip(
          message: hasPendingWrites ? "Saving offline..." : "All data synced",
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Row(
              key: ValueKey<bool>(hasPendingWrites),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasPendingWrites
                      ? Icons.cloud_upload_rounded
                      : Icons.cloud_done_rounded,
                  color: hasPendingWrites ? orangeIcon : greenIcon,
                  size: 16,
                ),
                if (hasPendingWrites) ...[
                  const SizedBox(width: 4),
                  Text(
                    "Saving offline",
                    style: TextStyle(
                      color: orangeText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
