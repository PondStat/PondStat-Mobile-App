import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/config/app_config_provider.dart';

part 'firebase_providers.g.dart';

@riverpod
FirebaseFirestore firebaseFirestore(Ref ref) {
  return FirebaseFirestore.instance;
}

@riverpod
FirebaseAuth firebaseAuth(Ref ref) {
  return FirebaseAuth.instance;
}

@riverpod
DocumentReference<Map<String, dynamic>> appBaseRef(Ref ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  final config = ref.watch(appConfigProvider);
  return firestore
      .collection('artifacts')
      .doc(config.appId)
      .collection('public')
      .doc('data');
}
