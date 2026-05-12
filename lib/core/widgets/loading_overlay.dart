import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isExiting;
  final List<String>? messages;
  final Duration? timeoutDuration;
  final VoidCallback? onTimeout;

  const LoadingOverlay({
    super.key,
    this.isExiting = false,
    this.messages,
    this.timeoutDuration = const Duration(seconds: 15),
    this.onTimeout,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late CurvedAnimation _curvedAnimation;
  Timer? _statusTimer;
  Timer? _timeoutTimer;
  final ValueNotifier<int> _messageIndexNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isTimedOutNotifier = ValueNotifier<bool>(false);

  late final List<String> _displayMessages;

  @override
  void initState() {
    super.initState();
    _displayMessages =
        widget.messages ??
        const [
          'Preparing the pond...',
          'Waking up the fish...',
          'Fetching water quality data...',
          'Calibrating sensors...',
          'Almost ready...',
        ];

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _curvedAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutSine,
    );

    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && !_isTimedOutNotifier.value) {
        _messageIndexNotifier.value =
            (_messageIndexNotifier.value + 1) % _displayMessages.length;
      }
    });

    if (widget.timeoutDuration != null) {
      _timeoutTimer = Timer(widget.timeoutDuration!, () {
        if (mounted) {
          _isTimedOutNotifier.value = true;
          // ignore: deprecated_member_use
          SemanticsService.announce(
            "Loading is taking longer than expected. You can cancel.",
            TextDirection.ltr,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _rippleController.dispose();
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    _messageIndexNotifier.dispose();
    _isTimedOutNotifier.dispose();
    super.dispose();
  }

  Widget _buildRipple(double animationValue, double baseSize, Color color) {
    final double size = baseSize + (animationValue * (baseSize * 0.5));
    final double opacity = 1.0 - animationValue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity * 0.15),
        border: Border.all(
          color: color.withValues(alpha: opacity * 0.5),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Size screenSize = MediaQuery.sizeOf(context);

    final double safeAnimationSize = (screenSize.height * 0.35).clamp(
      200.0,
      350.0,
    );

    return AnimatedOpacity(
      opacity: widget.isExiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Semantics(
        label: 'Loading PondStat app data, please wait.',
        liveRegion: true,
        child: PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: colorScheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: safeAnimationSize,
                        child: AnimatedBuilder(
                          animation: _rippleController,
                          builder: (context, child) {
                            final double pulseScale =
                                1.0 + (0.05 * _curvedAnimation.value);

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildRipple(
                                  _curvedAnimation.value,
                                  safeAnimationSize * 0.5,
                                  colorScheme.onPrimary,
                                ),
                                _buildRipple(
                                  (_curvedAnimation.value + 0.5) % 1.0,
                                  safeAnimationSize * 0.5,
                                  colorScheme.onPrimary,
                                ),
                                Transform.scale(
                                  scale: pulseScale,
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: colorScheme.onPrimary,
                                      shape: BoxShape.circle,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.water_drop,
                                      size: 48,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'PondStat',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isTimedOutNotifier,
                        builder: (context, isTimedOut, child) {
                          if (isTimedOut) {
                            return Column(
                              children: [
                                Text(
                                  "Taking longer than expected...",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                    letterSpacing: 0.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed:
                                      widget.onTimeout ??
                                      () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                  label: const Text("Cancel"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colorScheme.onPrimary,
                                    side: BorderSide(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return ValueListenableBuilder<int>(
                            valueListenable: _messageIndexNotifier,
                            builder: (context, messageIndex, child) {
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final inAnimation = Tween<Offset>(
                                        begin: const Offset(0.0, 0.5),
                                        end: Offset.zero,
                                      ).animate(animation);

                                      final outAnimation = Tween<Offset>(
                                        begin: const Offset(0.0, -0.5),
                                        end: Offset.zero,
                                      ).animate(animation);

                                      final bool isEntering =
                                          child.key ==
                                          ValueKey<int>(
                                            _messageIndexNotifier.value,
                                          );

                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: isEntering
                                              ? inAnimation
                                              : outAnimation,
                                          child: child,
                                        ),
                                      );
                                    },
                                child: ExcludeSemantics(
                                  child: Text(
                                    _displayMessages[messageIndex],
                                    key: ValueKey<int>(messageIndex),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.7,
                                      ),
                                      letterSpacing: 0.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Text(
                        'For Fisheries Students',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary.withValues(alpha: 0.54),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
