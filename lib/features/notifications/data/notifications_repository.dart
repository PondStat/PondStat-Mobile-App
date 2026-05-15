import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

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

class NotificationsRepository {
  static final NotificationsRepository _instance =
      NotificationsRepository._internal();
  factory NotificationsRepository() => _instance;
  NotificationsRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _notificationsCollection {
    final user = currentUser;
    if (user == null) return null;
    return FirestoreHelper.usersCollection
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
          developer.log(
            'Error in getNotificationsStream',
            name: 'notifications.repository',
            error: error,
            stackTrace: stackTrace,
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
          developer.log(
            'Error in getUnreadCountStream',
            name: 'notifications.repository',
            error: error,
            stackTrace: stackTrace,
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
      developer.log(
        'Error updating notification read status',
        error: e,
        name: 'notifications.repository',
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
      developer.log(
        'Error marking all as read',
        error: e,
        name: 'notifications.repository',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final collection = _notificationsCollection;
      if (collection == null) return;
      await collection.doc(notificationId).delete();
    } catch (e) {
      developer.log(
        'Error deleting notification',
        error: e,
        name: 'notifications.repository',
      );
    }
  }
}
