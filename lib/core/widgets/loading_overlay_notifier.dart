import 'dart:async';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/config/app_config_provider.dart';

part 'loading_overlay_notifier.g.dart';

class LoadingOverlayState {
  final String currentMessage;
  final bool isTimedOut;

  const LoadingOverlayState({
    required this.currentMessage,
    this.isTimedOut = false,
  });

  LoadingOverlayState copyWith({
    String? currentMessage,
    bool? isTimedOut,
  }) {
    return LoadingOverlayState(
      currentMessage: currentMessage ?? this.currentMessage,
      isTimedOut: isTimedOut ?? this.isTimedOut,
    );
  }
}

class LoadingOverlayArgs {
  final List<String>? messages;
  final Duration? timeoutDuration;

  const LoadingOverlayArgs({this.messages, this.timeoutDuration});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadingOverlayArgs &&
        _listEquals(other.messages, messages) &&
        other.timeoutDuration == timeoutDuration;
  }

  @override
  int get hashCode => messages.hashCode ^ timeoutDuration.hashCode;

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

@riverpod
class LoadingOverlayNotifier extends _$LoadingOverlayNotifier {
  Timer? _statusTimer;
  Timer? _timeoutTimer;
  int _messageIndex = 0;

  @override
  LoadingOverlayState build(LoadingOverlayArgs arg) {
    final config = ref.watch(appConfigProvider);
    final messages = arg.messages ?? config.defaultLoadingMessages;
    final timeout = arg.timeoutDuration ?? config.defaultTimeoutDuration;

    ref.onDispose(() {
      _statusTimer?.cancel();
      _timeoutTimer?.cancel();
    });

    _startTimers(messages, timeout);

    return LoadingOverlayState(currentMessage: messages.first);
  }

  void _startTimers(List<String> messages, Duration timeout) {
    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (state.isTimedOut) return;
      _messageIndex = (_messageIndex + 1) % messages.length;
      state = state.copyWith(currentMessage: messages[_messageIndex]);
    });

    _timeoutTimer = Timer(timeout, () {
      state = state.copyWith(isTimedOut: true);
      HapticFeedback.heavyImpact();
    });
  }

  void retry() {
    final config = ref.read(appConfigProvider);
    final messages = arg.messages ?? config.defaultLoadingMessages;
    final timeout = arg.timeoutDuration ?? config.defaultTimeoutDuration;

    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    _messageIndex = 0;
    state = state.copyWith(isTimedOut: false, currentMessage: messages.first);
    _startTimers(messages, timeout);
  }
}
