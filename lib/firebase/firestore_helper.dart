import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static const String appId = 'pondstat-app-v1';

  static CollectionReference<Map<String, dynamic>> get usersCollection {
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('users');
  }

  static CollectionReference<Map<String, dynamic>> get measurementsCollection {
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('measurements');
  }

  static CollectionReference<Map<String, dynamic>> get pondsCollection {
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('ponds');
  }

  static CollectionReference<Map<String, dynamic>> get customParametersCollection {
    return FirebaseFirestore.instance
        .collection('artifacts')
        .doc(appId)
        .collection('public')
        .doc('data')
        .collection('custom_parameters');
  }
}