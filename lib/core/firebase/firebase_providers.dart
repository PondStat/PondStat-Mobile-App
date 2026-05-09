import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/config/env_config.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final appBaseRefProvider = Provider<DocumentReference<Map<String, dynamic>>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('artifacts')
      .doc(EnvConfig.appId)
      .collection('public')
      .doc('data');
});