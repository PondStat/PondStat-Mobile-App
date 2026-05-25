import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/chat/data/chat_repository.dart';
import 'package:pondstat/features/chat/domain/models/pond_chat_message.dart';
import 'package:pondstat/features/chat/presentation/pond_chat_page.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockChatRepository extends Mock implements ChatRepository {}
class MockNotificationsRepository extends Mock implements NotificationsRepository {}

void main() {
  group('PondChatPage Widget Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockChatRepository mockChatRepo;
    late MockNotificationsRepository mockNotificationsRepo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockChatRepo = MockChatRepository();
      mockNotificationsRepo = MockNotificationsRepository();

      when(() => mockUser.uid).thenReturn('my-uid');
      when(() => mockUser.displayName).thenReturn('My Display Name');
      when(() => mockUser.photoURL).thenReturn(null);
      when(() => mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('renders empty state when there are no messages', (tester) async {
      when(() => mockChatRepo.getMessagesStream('pond-123'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            chatRepositoryProvider.overrideWithValue(mockChatRepo),
            notificationsRepositoryProvider.overrideWithValue(mockNotificationsRepo),
            isOfflineProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PondChatPage(
                pondId: 'pond-123',
                pondName: 'Test Pond',
                userRole: 'owner',
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Start loading
      await tester.pump(); // Render data

      expect(find.text('No messages yet'), findsOneWidget);
      expect(find.text('Type observation or note...'), findsOneWidget);
    });

    testWidgets('renders message list when messages exist', (tester) async {
      final messages = [
        PondChatMessage(
          id: 'msg-1',
          pondId: 'pond-123',
          senderId: 'collaborator-1',
          senderName: 'Jane Smith',
          message: 'Water looks very clean today.',
          createdAt: DateTime(2026, 5, 25, 10, 0),
        ),
        PondChatMessage(
          id: 'msg-2',
          pondId: 'pond-123',
          senderId: 'my-uid',
          senderName: 'My Display Name',
          message: 'Excellent. Have you checked the pH levels?',
          taggedParameter: 'pH',
          createdAt: DateTime(2026, 5, 25, 10, 5),
        ),
      ];

      when(() => mockChatRepo.getMessagesStream('pond-123'))
          .thenAnswer((_) => Stream.value(messages));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseAuthProvider.overrideWithValue(mockAuth),
            chatRepositoryProvider.overrideWithValue(mockChatRepo),
            notificationsRepositoryProvider.overrideWithValue(mockNotificationsRepo),
            isOfflineProvider.overrideWithValue(false),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PondChatPage(
                pondId: 'pond-123',
                pondName: 'Test Pond',
                userRole: 'owner',
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Water looks very clean today.'), findsOneWidget);
      expect(find.text('Excellent. Have you checked the pH levels?'), findsOneWidget);
      expect(find.text('Tagged: pH'), findsOneWidget);
    });
  });
}
