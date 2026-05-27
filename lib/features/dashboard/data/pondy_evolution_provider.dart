import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_companion_models.dart';
import 'package:clock/clock.dart';

final pondyEvolutionProvider = StreamProvider<PondyEvolutionState>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final user = auth.currentUser;
  if (user == null) {
    return Stream.value(const PondyEvolutionState.empty());
  }

  final pondRepo = ref.watch(pondRepositoryProvider);
  final monitoringRepo = ref.watch(monitoringRepositoryProvider);

  // Controller to handle custom stream events dynamically
  final controller = StreamController<PondyEvolutionState>();
  StreamSubscription? pondsSubscription;
  StreamSubscription? measurementsSubscription;

  void cleanUp() {
    pondsSubscription?.cancel();
    measurementsSubscription?.cancel();
  }

  ref.onDispose(() {
    cleanUp();
    controller.close();
  });

  pondsSubscription = pondRepo.getUserPondsStream(user.uid).listen((ponds) {
    measurementsSubscription?.cancel();

    if (ponds.isEmpty) {
      controller.add(const PondyEvolutionState.empty());
      return;
    }

    final pondIds = ponds.map((p) => p.id).toList();
    final cutoff = clock.now().subtract(const Duration(days: 30));
    final limitedPondIds = pondIds.take(30).toList();

    measurementsSubscription = monitoringRepo.measurementsCollection
        .where('pondId', whereIn: limitedPondIds)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .snapshots()
        .listen((snapshot) {
      final docs = snapshot.docs;

      final now = clock.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));
      final sevenDaysAgo = now.subtract(const Duration(days: 7));

      // Measurements in last 7 days
      final last7DaysDocs = docs.where((doc) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return timestamp != null && timestamp.isAfter(sevenDaysAgo);
      }).toList();

      // Measurements in last 3 days
      final last3DaysDocs = docs.where((doc) {
        final timestamp = (doc.data()['timestamp'] as Timestamp?)?.toDate();
        return timestamp != null && timestamp.isAfter(threeDaysAgo);
      }).toList();

      // Unique days with measurements
      final uniqueDays7Days = last7DaysDocs.map((doc) => doc.data()['dateKey'] as String?).whereType<String>().toSet();
      final uniqueDays30Days = docs.map((doc) => doc.data()['dateKey'] as String?).whereType<String>().toSet();

      // Evolve logic:
      // Level 3 (Crown) if 5+ unique days monitored in last 7 days
      // Level 2 (Hat) if 3-4 unique days monitored in last 7 days
      // Level 1 (Standard) otherwise
      final streakDays = uniqueDays7Days.length;
      int level = 1;
      if (streakDays >= 5) {
        level = 3;
      } else if (streakDays >= 3) {
        level = 2;
      }

      // Neglect: true if there are zero measurements in the last 3 days
      final isNeglected = last3DaysDocs.isEmpty;

      // Vibrant: true if monitored in last 7 days and zero alerts triggered
      final last7DaysAlerts = last7DaysDocs.where((doc) => doc.data()['alert'] != null).toList();
      final isVibrant = last7DaysDocs.isNotEmpty && last7DaysAlerts.isEmpty && !isNeglected;

      // statusMood: stable, warning, critical based on alerts in the last 7 days
      String statusMood = 'stable';
      if (last7DaysAlerts.isNotEmpty) {
        final hasCritical = last7DaysAlerts.any((doc) {
          final alert = doc.data()['alert'] as Map<String, dynamic>?;
          return alert?['tier'] == 'critical';
        });
        statusMood = hasCritical ? 'critical' : 'warning';
      }

      // Achievements
      // 1. First Week Streak: recorded measurements on 7 distinct days in the last 30 days
      final hasFirstWeekStreak = uniqueDays30Days.length >= 7;

      // 2. Perfect pH Month: pH Level was recorded in the last 30 days and had zero alerts
      final phDocs = docs.where((doc) => doc.data()['parameter'] == 'pH Level').toList();
      final hasPhRecords = phDocs.isNotEmpty;
      final hasPhAlerts = phDocs.any((doc) => doc.data()['alert'] != null);
      final hasPerfectPhMonth = hasPhRecords && !hasPhAlerts;

      // 3. Zero Alerts Week: at least 1 record in last 7 days and 0 alerts in last 7 days
      final hasZeroAlertsWeek = last7DaysDocs.isNotEmpty && last7DaysAlerts.isEmpty;

      controller.add(PondyEvolutionState(
        level: level,
        isVibrant: isVibrant,
        isNeglected: isNeglected,
        statusMood: statusMood,
        streakDays: uniqueDays30Days.length,
        hasFirstWeekStreak: hasFirstWeekStreak,
        hasPerfectPhMonth: hasPerfectPhMonth,
        hasZeroAlertsWeek: hasZeroAlertsWeek,
        hasAnyPond: true,
      ));
    }, onError: (err) {
      controller.addError(err);
    });
  }, onError: (err) {
    controller.addError(err);
  });

  return controller.stream;
});
