import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/core/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return AuthRepository(auth, notificationService);
});

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final FirebaseAuth _auth;
  final NotificationService _notificationService;

  AuthRepository(this._auth, this._notificationService);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '624574025589-5390binsi9sh8plk6ii0h929dtq63dvu.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      return null; // User canceled
    }

    if (!googleUser.email.endsWith('@up.edu.ph')) {
      await _googleSignIn.signOut();
      throw AuthException(
        'Only UP mail (@up.edu.ph) accounts are allowed to log in.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await _auth.signInWithCredential(
      credential,
    );
    final user = userCredential.user;

    if (user != null) {
      final userDoc = await FirestoreHelper.usersCollection.doc(user.uid).get();

      if (!userDoc.exists) {
        await FirestoreHelper.usersCollection.doc(user.uid).set({
          'fullName': user.displayName ?? 'New User',
          'email': user.email,
          'role': 'member',
          'assignedPond': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update FCM token on login
      await updateFcmToken();
    }

    return userCredential;
  }

  Future<void> updateFcmToken() async {
    final user = currentUser;
    if (user == null) return;

    final token = await _notificationService.getDeviceToken();
    if (token != null) {
      try {
        await FirestoreHelper.usersCollection.doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        developer.log(
          'Error updating FCM token',
          error: e,
          name: 'auth.repository',
        );
      }
    }
    // If token is null (e.g. permission denied), we DO NOT delete the existing token
    // to avoid wiping notifications for other devices.
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
