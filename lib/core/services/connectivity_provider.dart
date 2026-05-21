import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A StreamProvider that emits the current connectivity results.
final connectivityStreamProvider = StreamProvider<List<ConnectivityResult>>((ref) async* {
  // Yield initial connectivity status first
  try {
    final initial = await Connectivity().checkConnectivity().timeout(
      const Duration(seconds: 1),
      onTimeout: () => [ConnectivityResult.none],
    );
    yield initial;
  } catch (_) {
    yield [ConnectivityResult.none];
  }
  
  // Yield subsequent changes
  yield* Connectivity().onConnectivityChanged;
});

/// A Provider that determines if the device is currently offline (no internet connection).
final isOfflineProvider = Provider<bool>((ref) {
  final connectivityAsync = ref.watch(connectivityStreamProvider);
  return connectivityAsync.maybeWhen(
    data: (results) => results.contains(ConnectivityResult.none),
    orElse: () => false,
  );
});
