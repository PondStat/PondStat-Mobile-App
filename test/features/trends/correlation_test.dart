import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/theme/app_theme.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/correlation_tab.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  group('CorrelationTab Widget Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MonitoringRepository monitoringRepository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(() => mockUser.uid).thenReturn('test-user');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final baseRef = fakeFirestore.doc('artifacts/test-app-id/public/data');
      monitoringRepository = MonitoringRepository(
        baseRef,
        fakeFirestore,
        mockAuth,
        isOffline: () => false,
      );
    });

    testWidgets('renders empty state when there are no measurements', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(monitoringRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CorrelationTab(
                pondId: 'pond-123',
                species: 'tilapia',
                startDate: DateTime(2026, 5, 1),
                endDate: DateTime(2026, 5, 30),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Data Found'), findsOneWidget);
    });

    testWidgets('renders correlation matrix and scatter plot when data exists', (tester) async {
      final measurementsCol = fakeFirestore
          .collection('artifacts/test-app-id/public/data/measurements');

      final dates = [
        DateTime(2026, 5, 10),
        DateTime(2026, 5, 11),
        DateTime(2026, 5, 12),
      ];

      final phValues = [7.0, 7.5, 8.0];
      final doValues = [5.0, 6.0, 7.0];

      for (int i = 0; i < 3; i++) {
        final dateKey = "${dates[i].year}-${dates[i].month}-${dates[i].day}";
        await measurementsCol.add({
          'pondId': 'pond-123',
          'dateKey': dateKey,
          'timestamp': Timestamp.fromDate(dates[i]),
          'parameter': 'pH Level',
          'value': phValues[i],
          'type': 'water',
        });
        await measurementsCol.add({
          'pondId': 'pond-123',
          'dateKey': dateKey,
          'timestamp': Timestamp.fromDate(dates[i]),
          'parameter': 'Dissolved Oxygen',
          'value': doValues[i],
          'type': 'water',
        });
      }

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monitoringRepositoryProvider.overrideWithValue(monitoringRepository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: CorrelationTab(
                pondId: 'pond-123',
                species: 'tilapia',
                startDate: DateTime(2026, 5, 1),
                endDate: DateTime(2026, 5, 20),
              ),
            ),
          ),
        ),
      );

      await tester.pump(); // Starts loading
      await tester.pumpAndSettle(); // Renders grid and chart

      expect(find.text('CORRELATION MATRIX'), findsOneWidget);
      expect(find.text('SCATTER PLOT'), findsOneWidget);
      expect(find.text('1.00'), findsWidgets); // Perfect correlation of 1.00

      // Scroll the ListView down to bring the interpretation card into view
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Strong Positive'), findsOneWidget);
    });
  });
}
