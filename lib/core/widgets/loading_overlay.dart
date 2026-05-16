import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isExiting;
  final List<String>? messages;
  final Duration? timeoutDuration;
  final VoidCallback? onTimeout;
  final VoidCallback? onRetry;
  final ValueNotifier<String>? currentMessageNotifier;

  const LoadingOverlay({
    super.key,
    this.isExiting = false,
    this.messages,
    this.timeoutDuration = const Duration(seconds: 15),
    this.onTimeout,
    this.onRetry,
    this.currentMessageNotifier,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late CurvedAnimation _curvedAnimation;

  late AnimationController _waveController;

  Timer? _statusTimer;
  Timer? _timeoutTimer;

  final ValueNotifier<String> _currentMessage = ValueNotifier<String>('');
  final ValueNotifier<bool> _isTimedOutNotifier = ValueNotifier<bool>(false);

  late final List<String> _displayMessages;
  int _messageIndex = 0;

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

    _currentMessage.value =
        widget.currentMessageNotifier?.value ?? _displayMessages[0];

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _curvedAnimation = CurvedAnimation(
      parent: _rippleController,
      curve: Curves.easeOutSine,
    );

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    if (widget.currentMessageNotifier != null) {
      widget.currentMessageNotifier!.addListener(_onExternalMessageChanged);
    } else {
      _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted && !_isTimedOutNotifier.value) {
          _messageIndex = (_messageIndex + 1) % _displayMessages.length;
          _currentMessage.value = _displayMessages[_messageIndex];
          HapticFeedback.lightImpact();
        }
      });
    }

    if (widget.timeoutDuration != null) {
      _timeoutTimer = Timer(widget.timeoutDuration!, () {
        if (mounted) {
          _isTimedOutNotifier.value = true;
          HapticFeedback.heavyImpact();
          // ignore: deprecated_member_use
          SemanticsService.announce(
            "Loading is taking longer than expected. You can cancel or retry.",
            TextDirection.ltr,
          );
        }
      });
    }
  }

  void _onExternalMessageChanged() {
    if (mounted && widget.currentMessageNotifier != null) {
      _currentMessage.value = widget.currentMessageNotifier!.value;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    if (widget.currentMessageNotifier != null) {
      widget.currentMessageNotifier!.removeListener(_onExternalMessageChanged);
    }
    _curvedAnimation.dispose();
    _rippleController.dispose();
    _waveController.dispose();
    _statusTimer?.cancel();
    _timeoutTimer?.cancel();
    _currentMessage.dispose();
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
                          animation: Listenable.merge([
                            _rippleController,
                            _waveController,
                          ]),
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
                                    width: 96,
                                    height: 96,
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
                                    child: ClipOval(
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _WaterWavePainter(
                                                animationValue:
                                                    _waveController.value,
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.15),
                                                waveHeight: 8.0,
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: CustomPaint(
                                              painter: _WaterWavePainter(
                                                animationValue:
                                                    _waveController.value + 0.3,
                                                color: colorScheme.primary
                                                    .withValues(alpha: 0.3),
                                                waveHeight: 12.0,
                                              ),
                                            ),
                                          ),
                                          Center(
                                            child: Icon(
                                              Icons.water_drop,
                                              size: 48,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
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
                          shadows: [
                            const Shadow(
                              offset: Offset(0, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: ValueListenableBuilder<bool>(
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
                                      shadows: [
                                        const Shadow(
                                          offset: Offset(0, 1),
                                          blurRadius: 2,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed:
                                            widget.onTimeout ??
                                            () => Navigator.of(context).pop(),
                                        icon: const Icon(Icons.close_rounded),
                                        label: const Text("Cancel"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          side: BorderSide(
                                            color: colorScheme.onPrimary
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                      if (widget.onRetry != null) ...[
                                        const SizedBox(width: 12),
                                        FilledButton.tonalIcon(
                                          onPressed: () {
                                            _isTimedOutNotifier.value = false;
                                            widget.onRetry?.call();
                                            // Reset timeout timer to try again
                                            _timeoutTimer?.cancel();
                                            if (widget.timeoutDuration !=
                                                null) {
                                              _timeoutTimer = Timer(
                                                widget.timeoutDuration!,
                                                () {
                                                  if (mounted) {
                                                    _isTimedOutNotifier.value =
                                                        true;
                                                    HapticFeedback.heavyImpact();
                                                  }
                                                },
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                          ),
                                          label: const Text("Retry"),
                                          style: FilledButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.onPrimary,
                                            foregroundColor:
                                                colorScheme.primary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              );
                            }

                            return ValueListenableBuilder<String>(
                              valueListenable: _currentMessage,
                              builder: (context, currentMsg, child) {
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
                                            ValueKey<String>(currentMsg);

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
                                      currentMsg,
                                      key: ValueKey<String>(currentMsg),
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: colorScheme.onPrimary
                                                .withValues(alpha: 0.9),
                                            letterSpacing: 0.5,
                                            fontWeight: FontWeight.w600,
                                            shadows: [
                                              const Shadow(
                                                offset: Offset(0, 1),
                                                blurRadius: 2,
                                                color: Colors.black26,
                                              ),
                                            ],
                                          ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
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
                          color: colorScheme.onPrimary.withValues(alpha: 0.8),
                          letterSpacing: 1.0,
                          shadows: [
                            const Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
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

class _WaterWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double waveHeight;

  _WaterWavePainter({
    required this.animationValue,
    required this.color,
    required this.waveHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final yOffset = size.height * 0.55; // Base height of the water

    path.moveTo(0, yOffset);

    // Draw the sine wave
    for (double i = 0; i <= size.width; i++) {
      // Calculate sine value based on x position and animation phase
      final dx = i;
      final dy =
          math.sin(
                (i / size.width * math.pi * 2) + (animationValue * math.pi * 2),
              ) *
              waveHeight +
          yOffset;
      path.lineTo(dx, dy);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaterWavePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color ||
        oldDelegate.waveHeight != waveHeight;
  }
}
