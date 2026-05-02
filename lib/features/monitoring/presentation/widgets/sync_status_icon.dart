import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class SyncStatusIcon extends StatelessWidget {
  const SyncStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .limit(1)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        bool hasPendingWrites = snapshot.hasData
            ? snapshot.data!.metadata.hasPendingWrites
            : false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasPendingWrites
                  ? Icons.cloud_upload_rounded
                  : Icons.cloud_done_rounded,
              color: hasPendingWrites
                  ? Colors.orange.shade400
                  : Colors.green.shade400,
              size: 16,
            ),
            if (hasPendingWrites) ...[
              const SizedBox(width: 4),
              Text(
                "Saving offline",
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
