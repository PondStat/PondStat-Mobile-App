import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_companion.dart';
import '../pondy_aquarium_page.dart';

class PondyAquariumCard extends StatefulWidget {
  final String statusMood; // 'stable', 'warning', 'critical'

  const PondyAquariumCard({
    super.key,
    this.statusMood = 'stable',
  });

  @override
  State<PondyAquariumCard> createState() => _PondyAquariumCardState();
}

class _PondyAquariumCardState extends State<PondyAquariumCard> {
  String _bubbleText = "";
  Timer? _tipCycleTimer;
  int _tipIndex = 0;
  bool _isCustomMessageActive = false;
  Timer? _customMessageResetTimer;

  final List<String> _pondTips = [
    "Tip: Tap my aquarium tank to open the immersive full-screen ecosystem! 🐢🫧",
    "Tip: Measure Dissolved Oxygen (DO) at sunrise when it is at its lowest level!",
    "Tip: Keep water transparency within 30-40cm for ideal phytoplankton densities.",
    "Tip: FCR is optimized when water temperatures stay between 28°C and 32°C.",
    "Tip: Negative Average Daily Gain? Inspect for elevated ammonia (NH3) stressors!",
    "Tip: Always sanitize sampling beakers before recording parameter replicates.",
    "Tip: Warm water holds less dissolved oxygen than cool water. Monitor aeration closely!",
    "Tip: Yellow colony count exceeding 10^5 CFU/ml indicates potential Vibrio risk.",
    "Tip: Regular weekly ABW sampling ensures accurate feed calculation forecasts!",
  ];

  @override
  void initState() {
    super.initState();
    _bubbleText = _getGreetingMessage();
    // Cycle tips every 12 seconds
    _tipCycleTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      if (!_isCustomMessageActive && mounted) {
        setState(() {
          _tipIndex = (_tipIndex + 1) % _pondTips.length;
          _bubbleText = _pondTips[_tipIndex];
        });
      }
    });
  }

  @override
  void dispose() {
    _tipCycleTimer?.cancel();
    _customMessageResetTimer?.cancel();
    super.dispose();
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (widget.statusMood == 'critical') {
      return "Oh no! Some parameters look critical. Let's fix them together!";
    } else if (widget.statusMood == 'warning') {
      return "Pond parameters are showing warnings. Keep an eye on them!";
    }

    if (hour < 12) {
      return "Good morning! Ready to check our water parameters today?";
    } else if (hour < 17) {
      return "Good afternoon! Tap on my tank to drop feed pellets!";
    } else {
      return "Good evening! Everything is quiet and peaceful in the ponds.";
    }
  }

  void _handlePondyEat(String message) {
    _customMessageResetTimer?.cancel();
    setState(() {
      _bubbleText = message;
      _isCustomMessageActive = true;
    });

    // Revert back to tips rotation after 5 seconds
    _customMessageResetTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _isCustomMessageActive = false;
          _bubbleText = _pondTips[_tipIndex];
        });
      }
    });
  }

  void _cycleTipManually() {
    _customMessageResetTimer?.cancel();
    setState(() {
      _isCustomMessageActive = false;
      _tipIndex = (_tipIndex + 1) % _pondTips.length;
      _bubbleText = _pondTips[_tipIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color: isDark
                  ? Colors.white12
                  : colorScheme.primary.withValues(alpha: 0.12),
              width: 1.5,
            ),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                      colorScheme.surfaceContainerLowest.withValues(alpha: 0.2),
                    ]
                  : [
                      Colors.white,
                      colorScheme.primary.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              // 1. Interactive Aquarium Tank Window
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          PondyAquariumPage(statusMood: widget.statusMood),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                      transitionDuration: const Duration(milliseconds: 600),
                    ),
                  );
                },
                child: Container(
                  width: 120,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF00ACC1).withValues(alpha: 0.4)
                          : colorScheme.primary.withValues(alpha: 0.2),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: isDark ? 0.15 : 0.08),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF006064), // Deep Teal
                        Color(0xFF00838F),
                        Color(0xFF00ACC1), // Aquatic turquoise
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: PondyCompanion(
                      statusMood: widget.statusMood,
                      onEat: _handlePondyEat,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 2. Interactive Speech Bubble
              Expanded(
                child: GestureDetector(
                  onTap: _cycleTipManually,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Speech bubble container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(minHeight: 90),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Pondy",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: colorScheme.primary,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 11,
                                  color: colorScheme.primary.withValues(alpha: 0.8),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                _bubbleText,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : Colors.grey.shade800,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Left arrow pointer pointing to aquarium
                      Positioned(
                        left: -8,
                        top: 45,
                        child: CustomPaint(
                          painter: _SpeechBubbleArrowPainter(
                            color: isDark
                                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
                                : Colors.white,
                            borderColor: isDark
                                ? Colors.white10
                                : colorScheme.onSurface.withValues(alpha: 0.08),
                          ),
                          child: const SizedBox(width: 8, height: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechBubbleArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  _SpeechBubbleArrowPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);
    
    // Draw boundary border only on the two angled legs
    final borderPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeechBubbleArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}
