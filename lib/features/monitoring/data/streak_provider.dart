import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final pondStreakProvider = StreamProvider.family<int, String>((ref, pondId) {
  final repository = ref.watch(monitoringRepositoryProvider);
  
  return repository.measurementsCollection
      .where('pondId', isEqualTo: pondId)
      .orderBy('timestamp', descending: true)
      .limit(200)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return 0;
    
    // 1. Extract unique dates in local time
    final Set<DateTime> uniqueDates = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final timestamp = data['timestamp'] as Timestamp?;
      if (timestamp != null) {
        final date = timestamp.toDate();
        // Normalize to local midnight to prevent time-of-day offsets from breaking streaks
        uniqueDates.add(DateTime(date.year, date.month, date.day));
      }
    }
    
    // 2. Sort unique dates descending
    final sortedDates = uniqueDates.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    // 3. Determine if streak is active (must have recorded today or yesterday)
    final hasToday = sortedDates.contains(today);
    final hasYesterday = sortedDates.contains(yesterday);
    
    if (!hasToday && !hasYesterday) {
      return 0; // Streak reset
    }
    
    // 4. Count consecutive days backward
    int streakCount = 0;
    DateTime currentCheckDay = hasToday ? today : yesterday;
    
    while (uniqueDates.contains(currentCheckDay)) {
      streakCount++;
      currentCheckDay = currentCheckDay.subtract(const Duration(days: 1));
    }
    
    return streakCount;
  });
});
