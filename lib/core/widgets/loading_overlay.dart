import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/widgets/loading_overlay_notifier.dart';

class LoadingOverlay extends ConsumerStatefulWidget {
  final bool isExiting;
  final List<String>? messages;
  final Duration? timeoutDuration;
  final VoidCallback? onTimeout;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const LoadingOverlay({
    super.key,
    this.isExiting = false,
    this.messages,
    this.timeoutDuration,
    this.onTimeout,
    this.onRetry,
    this.onCancel,
  });

  @override
  ConsumerState<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends ConsumerState<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late CurvedAnimation _curvedAnimation;

  late AnimationController _waveController;
  late LoadingOverlayArgs _args;

  @override
  void initState() {
    super.initState();
    _args = LoadingOverlayArgs(
      messages: widget.messages,
      timeoutDuration: widget.timeoutDuration,
    );

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
  }

  @override
  void dispose() {
    _curvedAnimation.dispose();
    _rippleController.dispose();
    _waveController.dispose();
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

    final loadingState = ref.watch(loadingOverlayProvider(_args));

    // Modern Semantics Announcement
    ref.listen(loadingOverlayProvider(_args).select((s) => s.isTimedOut),
        (previous, isTimedOut) {
      if (isTimedOut && previous != true) {
        if (widget.onTimeout != null) {
          widget.onTimeout!();
        }
        // ignore: deprecated_member_use
        SemanticsService.announce(
          "Loading is taking longer than expected. You can cancel or retry.",
          TextDirection.ltr,
        );
      }
    });

    return AnimatedOpacity(
      opacity: widget.isExiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Semantics(
        label: 'Loading PondStat app data, please wait.',
        liveRegion: true,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldCancel = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Loading?'),
                content: const Text(
                  'Are you sure you want to cancel this operation?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Yes, Cancel'),
                  ),
                ],
              ),
            );
            if (shouldCancel == true && context.mounted) {
              if (widget.onCancel != null) {
                widget.onCancel!();
              }
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    color: colorScheme.surface.withValues(alpha: 0.95),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: safeAnimationSize,
                        child: RepaintBoundary(
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
                                    colorScheme.onSurface,
                                  ),
                                  _buildRipple(
                                    (_curvedAnimation.value + 0.5) % 1.0,
                                    safeAnimationSize * 0.5,
                                    colorScheme.onSurface,
                                  ),
                                  Transform.scale(
                                    scale: pulseScale,
                                    child: Container(
                                      width: 96,
                                      height: 96,
                                      decoration: BoxDecoration(
                                        color: colorScheme.onSurface,
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
                                                  color: colorScheme.surface
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
                                                  color: colorScheme.surface
                                                      .withValues(alpha: 0.3),
                                                  waveHeight: 12.0,
                                                ),
                                              ),
                                            ),
                                            Center(
                                              child: Icon(
                                                Icons.water_drop,
                                                size: 48,
                                                color: colorScheme.surface,
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
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          loadingState.currentMessage,
                          key: ValueKey<String>(loadingState.currentMessage),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (loadingState.isTimedOut)
                        Column(
                          children: [
                            Text(
                              'This is taking longer than usual...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.onCancel != null) ...[
                                  OutlinedButton(
                                    onPressed: () {
                                      widget.onCancel!();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                FilledButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(loadingOverlayProvider(_args).notifier)
                                        .retry();
                                    if (widget.onRetry != null) {
                                      widget.onRetry!();
                                    }
                                  },
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Keep Waiting'),
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
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
    final yOffset = size.height * 0.6; // Fill bottom 40%

    path.moveTo(0, yOffset);

    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset +
            math.sin((i / size.width * 2 * math.pi) +
                    (animationValue * 2 * math.pi)) *
                waveHeight,
      );
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
