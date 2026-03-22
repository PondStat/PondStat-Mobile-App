import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_helper.dart';
import 'package:flutter/foundation.dart';

class UserLogHelper {
  static Future<void> logAction({
    required String action,
    required String entityType,
    String? pondId,
    String? pondName,
    String? category,
    String? parameter,
    String? unit,
    String? dateKey,
    String? timeString,
    double? averageValue,
    Map<String, double>? pointValues,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirestoreHelper.userLogsCollection.add({
        'userId': user?.uid,
        'userEmail': user?.email,
        'userName': user?.displayName,
        'action': action,
        'entityType': entityType,
        'pondId': pondId,
        'pondName': pondName,
        'category': category,
        'parameter': parameter,
        'unit': unit,
        'dateKey': dateKey,
        'timeString': timeString,
        'averageValue': averageValue,
        'pointValues': pointValues,
        'extra': extra ?? {},
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Error logging user action: $e");
    }
  }
}