import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A mixin that provides offline-aware write capabilities to Firestore repositories.
/// 
/// It routes writes through a timeout or background queue depending on the connection status.
mixin OfflineRepositoryMixin {
  /// A callback that returns whether the app is currently offline.
  bool Function() get isOffline;

  /// Executes a write operation. If offline, the write is executed asynchronously
  /// in the background without awaiting, preventing the UI from freezing.
  /// If online, it awaits completion with a 2-second timeout to handle slow networks gracefully.
  Future<void> runWrite(Future<void> Function() writeOperation) async {
    if (isOffline()) {
      unawaited(writeOperation().catchError((e) {
        // Silently catch write errors on offline queue
      }));
      return;
    }

    try {
      await writeOperation().timeout(
        const Duration(seconds: 2),
      );
    } on TimeoutException {
      // Return gracefully; Firestore will complete in background
      return;
    }
  }

  /// Commits a batch write with connection-aware timeout handling.
  Future<void> commitBatchWithTimeout(WriteBatch batch) async {
    await runWrite(() => batch.commit());
  }
}
