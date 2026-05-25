import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pondstat/features/chat/data/chat_repository.dart';
import 'package:pondstat/features/chat/domain/models/pond_chat_message.dart';

class MockFirebaseStorage extends Mock implements FirebaseStorage {}
class MockReference extends Mock implements Reference {}
class MockUploadTask extends Mock implements UploadTask {}
class MockTaskSnapshot extends Mock implements TaskSnapshot {}

void main() {
  group('ChatRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseStorage mockStorage;
    late ChatRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockStorage = MockFirebaseStorage();
      final baseRef = fakeFirestore.doc('artifacts/test-app-id/public/data');
      repository = ChatRepository(baseRef, mockStorage, isOffline: () => false);
    });

    test('sendMessage saves message to subcollection under pond', () async {
      await repository.sendMessage(
        pondId: 'pond-123',
        senderId: 'user-123',
        senderName: 'John Doe',
        senderPhotoUrl: 'https://avatar.url',
        message: 'Hello pond collaborators!',
        taggedParameter: 'pH',
      );

      final snapshot = await repository.getChatsCollection('pond-123').get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data.pondId, 'pond-123');
      expect(data.senderId, 'user-123');
      expect(data.senderName, 'John Doe');
      expect(data.senderPhotoUrl, 'https://avatar.url');
      expect(data.message, 'Hello pond collaborators!');
      expect(data.taggedParameter, 'pH');
      expect(data.imageUrl, isNull);
    });

    test('getMessagesStream streams messages sorted by createdAt', () async {
      final col = repository.getChatsCollection('pond-123');
      
      final msg1 = PondChatMessage(
        id: 'msg-1',
        pondId: 'pond-123',
        senderId: 'u1',
        senderName: 'U1',
        message: 'First',
      );

      final msg2 = PondChatMessage(
        id: 'msg-2',
        pondId: 'pond-123',
        senderId: 'u2',
        senderName: 'U2',
        message: 'Second',
      );

      await col.doc(msg1.id).set(msg1);
      await col.doc(msg2.id).set(msg2);

      final stream = repository.getMessagesStream('pond-123');
      final firstEmission = await stream.first;

      expect(firstEmission.length, 2);
      expect(firstEmission[0].id, 'msg-1');
      expect(firstEmission[1].id, 'msg-2');
    });
  });
}
