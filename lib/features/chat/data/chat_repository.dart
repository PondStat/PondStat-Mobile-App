import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/chat/domain/models/pond_chat_message.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';
import 'package:pondstat/core/firebase/offline_repository_mixin.dart';

part 'chat_repository.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final storage = ref.watch(firebaseStorageProvider);
  final isOffline = ref.watch(isOfflineProvider);
  return ChatRepository(
    baseRef,
    storage,
    isOffline: () => isOffline,
  );
}

@riverpod
Stream<List<PondChatMessage>> pondMessages(Ref ref, String pondId) {
  return ref.watch(chatRepositoryProvider).getMessagesStream(pondId);
}

class ChatRepository with OfflineRepositoryMixin {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseStorage _storage;
  @override
  final bool Function() isOffline;

  ChatRepository(
    this._baseRef,
    this._storage, {
    required this.isOffline,
  });

  CollectionReference<PondChatMessage> getChatsCollection(String pondId) {
    return _baseRef
        .collection('ponds')
        .doc(pondId)
        .collection('chats')
        .withConverter<PondChatMessage>(
          fromFirestore: (snapshot, _) {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return PondChatMessage.fromJson(data);
          },
          toFirestore: (message, _) => message.toJson(),
        );
  }

  Stream<List<PondChatMessage>> getMessagesStream(String pondId) {
    return getChatsCollection(pondId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> sendMessage({
    required String pondId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String message,
    String? imageUrl,
    String? taggedParameter,
  }) async {
    await runWrite(() async {
      final chatsCol = getChatsCollection(pondId);
      final newDocRef = chatsCol.doc();
      final chatMessage = PondChatMessage(
        id: newDocRef.id,
        pondId: pondId,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        message: message,
        imageUrl: imageUrl,
        taggedParameter: taggedParameter,
        createdAt: null, // Set via serverTimestamp
      );

      final rawRef = _baseRef
          .collection('ponds')
          .doc(pondId)
          .collection('chats')
          .doc(newDocRef.id);
      final json = chatMessage.toJson();
      json['createdAt'] = FieldValue.serverTimestamp();
      await rawRef.set(json);
    });
  }

  Future<String> uploadChatImage(String pondId, String messageId, String localFilePath) async {
    final file = File(localFilePath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist at $localFilePath');
    }

    final storageRef = _storage
        .ref()
        .child('ponds')
        .child(pondId)
        .child('chats')
        .child('$messageId.jpg');

    final uploadTask = storageRef.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
