import 'dart:async';
import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/core/services/logging/app_logger.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/services/notification_service.dart';

part 'auth_repository.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final storage = ref.watch(firebaseStorageProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final logger = ref.watch(appLoggerProvider);
  final repository = AuthRepository(baseRef, auth, storage, notificationService, logger);
  ref.onDispose(repository.dispose);
  return repository;
}

@riverpod
Stream<User?> userChanges(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return auth.userChanges();
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
  final FirebaseStorage _storage;
  final NotificationService _notificationService;
  final AppLogger _log;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<User?>? _authStateSub;

  AuthRepository(this._baseRef, this._auth, this._storage, this._notificationService, this._log) {
    // SRP: Listen for FCM token refreshes and persist to Firestore.
    // The NotificationService exposes the stream but does NOT write to the DB.
    _tokenRefreshSub = _notificationService.onTokenRefresh.listen(
      (newToken) => _persistFcmToken(newToken),
    );

    // Auto-heal/sync user Firestore document and sync FCM token on state changes (login, app launch, etc.)
    _authStateSub = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _ensureUserDocument(user);
        updateFcmToken();
      }
    });
  }

  /// Clean up listeners.
  void dispose() {
    _tokenRefreshSub?.cancel();
    _authStateSub?.cancel();
  }

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
    return userCredential;
  }

  Future<void> updateFcmToken() async {
    final user = currentUser;
    if (user == null) return;

    final token = await _notificationService.getDeviceToken();
    if (token != null) {
      await _persistFcmToken(token);
    }
    // If token is null (e.g. permission denied), we DO NOT delete the existing token
    // to avoid wiping notifications for other devices.
  }

  /// Persists an FCM token to Firestore for the current user.
  /// Called both on login ([updateFcmToken]) and on token refresh.
  Future<void> _persistFcmToken(String token) async {
    final user = currentUser;
    if (user == null) return;

    try {
      await usersCollection.doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _log.error(
        'Error persisting FCM token',
        error: e,
        tag: 'AUTH',
      );
    }
  }

  /// Ensures the user's Firestore document exists and is properly synced.
  Future<void> _ensureUserDocument(User? user) async {
    if (user == null) return;

    try {
      final userDoc = await usersCollection.doc(user.uid).get();

      if (!userDoc.exists) {
        await usersCollection.doc(user.uid).set({
          'fullName': user.displayName ?? 'New User',
          'email': user.email?.toLowerCase() ?? '',
          'role': 'member',
          'assignedPond': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _log.info('Created missing user document in Firestore for UID: ${user.uid}', tag: 'AUTH');
      } else {
        // Sync: Ensure existing user emails are saved in lowercase.
        final data = userDoc.data();
        final currentEmail = data?['email'] as String?;
        if (currentEmail != null && currentEmail != currentEmail.toLowerCase()) {
          await usersCollection.doc(user.uid).update({
            'email': currentEmail.toLowerCase(),
          });
          _log.info('Normalized email to lowercase for UID: ${user.uid}', tag: 'AUTH');
        }
      }
    } catch (e) {
      _log.error(
        'Error ensuring user document exists in Firestore',
        error: e,
        tag: 'AUTH',
      );
    }
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  /// Uploads a profile picture to Firebase Storage and updates the user's photo URL in
  /// both FirebaseAuth and Firestore.
  Future<String> uploadProfilePicture(String localFilePath) async {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final file = File(localFilePath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist at $localFilePath');
    }

    try {
      // 1. Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile_pic.jpg');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Update FirebaseAuth photoURL
      await user.updatePhotoURL(downloadUrl);

      // 3. Update Firestore users collection document
      await usersCollection.doc(user.uid).set({
        'photoUrl': downloadUrl,
      }, SetOptions(merge: true));

      // 4. Force reload user so local changes take effect immediately
      await user.reload();

      _log.info(
        'Successfully uploaded profile picture and updated photo URL for UID: ${user.uid}',
        tag: 'AUTH',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      _log.error(
        'Error uploading profile picture',
        error: e,
        stackTrace: stackTrace,
        tag: 'AUTH',
      );
      rethrow;
    }
  }
}
