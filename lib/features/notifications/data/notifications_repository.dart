import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';

part 'notifications_repository.g.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? pondId;
  final String? measurementId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.isRead,
    this.pondId,
    this.measurementId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      pondId: data['pondId'] as String?,
      measurementId: data['measurementId'] as String?,
    );
  }
}

@riverpod
NotificationsRepository notificationsRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final logger = ref.watch(appLoggerProvider);
  return NotificationsRepository(baseRef, firestore, auth, logger);
}

class NotificationsRepository {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final AppLogger _log;

  NotificationsRepository(this._baseRef, this._firestore, this._auth, this._log);

  User? get currentUser => _auth.currentUser;

  // ─── Collection References ───────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _baseRef.collection('users');

  CollectionReference<Map<String, dynamic>>? get _notificationsCollection {
    final user = currentUser;
    if (user == null) return null;
    return usersCollection
        .doc(user.uid)
        .collection('notifications');
  }

  Stream<List<NotificationModel>> getNotificationsStream() {
    final collection = _notificationsCollection;
    if (collection == null) return Stream.value([]);

    return collection
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        )
        .handleError((error, stackTrace) {
          _log.error(
            'Error in getNotificationsStream',
            error: error,
            stackTrace: stackTrace,
            tag: 'NOTIFICATIONS',
          );
          throw error;
        });
  }

  Stream<int> getUnreadCountStream() {
    final collection = _notificationsCollection;
    if (collection == null) return Stream.value(0);

    return collection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error, stackTrace) {
          _log.error(
            'Error in getUnreadCountStream',
            error: error,
            stackTrace: stackTrace,
            tag: 'NOTIFICATIONS',
          );
          throw error;
        });
  }

  Future<void> markAsRead(String notificationId) async {
    await updateReadStatus(notificationId, true);
  }

  Future<void> updateReadStatus(String notificationId, bool isRead) async {
    try {
      final collection = _notificationsCollection;
      if (collection == null) return;
      await collection.doc(notificationId).update({'isRead': isRead});
    } catch (e) {
      _log.error(
        'Error updating notification read status',
        error: e,
        tag: 'NOTIFICATIONS',
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final collection = _notificationsCollection;
      if (collection == null) return;

      final unread = await collection.where('isRead', isEqualTo: false).get();

      if (unread.docs.isEmpty) return;

      const batchSize = 400;
      final docs = unread.docs;

      for (var i = 0; i < docs.length; i += batchSize) {
        final end = (i + batchSize < docs.length) ? i + batchSize : docs.length;
        final chunk = docs.sublist(i, end);

        final batch = _firestore.batch();
        for (var doc in chunk) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      _log.error(
        'Error marking all as read',
        error: e,
        tag: 'NOTIFICATIONS',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final collection = _notificationsCollection;
      if (collection == null) return;
      await collection.doc(notificationId).delete();
    } catch (e) {
      _log.error(
        'Error deleting notification',
        error: e,
        tag: 'NOTIFICATIONS',
      );
    }
  }

  Future<void> sendNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? pondId,
  }) async {
    try {
      await usersCollection
          .doc(recipientUserId)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'pondId':? pondId,
      });
      _log.info(
        'Sent notification to $recipientUserId: "$title"',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      _log.error(
        'Error sending notification to $recipientUserId',
        error: e,
        stackTrace: stackTrace,
        tag: 'NOTIFICATIONS',
      );
      rethrow;
    }
  }

  Future<void> notifyPondMembers({
    required String pondId,
    required String title,
    required String body,
  }) async {
    try {
      final currentUserId = currentUser?.uid;
      final pondDoc = await _baseRef.collection('ponds').doc(pondId).get();
      if (!pondDoc.exists) return;

      final data = pondDoc.data();
      if (data == null) return;

      final roles = data['roles'] as Map<String, dynamic>? ?? {};
      final otherMemberIds = roles.keys.where((uid) => uid != currentUserId).toList();

      for (final recipientUserId in otherMemberIds) {
        await sendNotification(
          recipientUserId: recipientUserId,
          title: title,
          body: body,
          pondId: pondId,
        );
      }
    } catch (e, stackTrace) {
      _log.error(
        'Error in notifyPondMembers for pond $pondId',
        error: e,
        stackTrace: stackTrace,
        tag: 'NOTIFICATIONS',
      );
    }
  }
}
