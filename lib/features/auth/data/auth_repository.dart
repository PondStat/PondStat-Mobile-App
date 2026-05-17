import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/services/notification_service.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  return AuthRepository(baseRef, auth, notificationService, logger);
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthRepository {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseAuth _auth;
  final NotificationService _notificationService;
  final AppLogger _log;

  AuthRepository(this._baseRef, this._auth, this._notificationService, this._log);

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '624574025589-5390binsi9sh8plk6ii0h929dtq63dvu.apps.googleusercontent.com',
  );

  // ─── Collection References ───────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _baseRef.collection('users');

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
      final userDoc = await usersCollection.doc(user.uid).get();

      if (!userDoc.exists) {
        await usersCollection.doc(user.uid).set({
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
        await usersCollection.doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        _log.error(
          'Error updating FCM token',
          error: e,
          tag: 'AUTH',
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
