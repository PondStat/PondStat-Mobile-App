import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/dashboard/data/pondy_evolution_provider.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_companion.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_companion_models.dart';
import '../pondy_aquarium_page.dart';

class PondyAquariumCard extends ConsumerStatefulWidget {
  final String statusMood; // 'stable', 'warning', 'critical'

  const PondyAquariumCard({
    super.key,
    this.statusMood = 'stable',
  });

  @override
  ConsumerState<PondyAquariumCard> createState() => _PondyAquariumCardState();
}

class _PondyAquariumCardState extends ConsumerState<PondyAquariumCard> {
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
    _bubbleText = _getGreetingMessage(widget.statusMood);
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

  String _getGreetingMessage(String mood) {
    final hour = DateTime.now().hour;
    if (mood == 'critical') {
      return "Oh no! Some parameters look critical. Let's fix them together!";
    } else if (mood == 'warning') {
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

    final evolutionAsync = ref.watch(pondyEvolutionProvider);
    final evolution = evolutionAsync.value ?? const PondyEvolutionState.empty();
    final currentMood = widget.statusMood == 'stable' ? evolution.statusMood : widget.statusMood;

    ref.listen<AsyncValue<PondyEvolutionState>>(pondyEvolutionProvider, (previous, next) {
      final prevMood = previous?.value?.statusMood;
      final nextMood = next.value?.statusMood;
      if (nextMood != null && nextMood != prevMood && !_isCustomMessageActive) {
        setState(() {
          _bubbleText = _getGreetingMessage(widget.statusMood == 'stable' ? nextMood : widget.statusMood);
        });
      }
    });

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
                          PondyAquariumPage(statusMood: currentMood),
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
                      statusMood: currentMood,
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
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.mediumImpact();
                                    _showAchievementsDialog(context, ref);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_rounded,
                                      size: 16,
                                      color: Colors.amber,
                                    ),
                                  ),
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

  void _showAchievementsDialog(BuildContext context, WidgetRef ref) {
    final evolution = ref.read(pondyEvolutionProvider).value ?? const PondyEvolutionState.empty();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white12 : colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Achievements",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),

                    // Pondy's Current Level Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: evolution.level == 3
                              ? [Colors.amber.shade700.withValues(alpha: 0.25), Colors.amber.shade900.withValues(alpha: 0.1)]
                              : evolution.level == 2
                                  ? [colorScheme.primary.withValues(alpha: 0.2), colorScheme.primary.withValues(alpha: 0.05)]
                                  : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: evolution.level == 3
                              ? Colors.amber.withValues(alpha: 0.4)
                              : evolution.level == 2
                                  ? colorScheme.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white60,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              evolution.level == 3
                                  ? "👑"
                                  : evolution.level == 2
                                      ? "🤠"
                                      : "🐢",
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pondy Evolution: Level ${evolution.level}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: evolution.level == 3
                                        ? Colors.amber.shade800
                                        : evolution.level == 2
                                            ? colorScheme.primary
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  evolution.level == 3
                                      ? "Monarch: Pondy is wearing the Golden Crown! Keep up the brilliant monitoring streak."
                                      : evolution.level == 2
                                          ? "Cowboy Scout: Pondy wears a cool Cowboy Hat. Active monitoring is going great!"
                                          : "Hatchling: Standard form. Monitored less than 3 days in the past week.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Streak Activity Progress
                    Text(
                      "Monitoring Activity",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Active Days (Past 30d)",
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${evolution.streakDays} / 30 days",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (evolution.streakDays / 30).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Badges Section
                    Text(
                      "Badges & Streaks",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildBadgeTile(
                      context,
                      title: "First Week Streak",
                      description: "Record measurements on 7 distinct days in the last 30 days.",
                      icon: Icons.calendar_month_rounded,
                      unlocked: evolution.hasFirstWeekStreak,
                      badgeColor: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeTile(
                      context,
                      title: "Perfect pH Month",
                      description: "Record pH values and keep them within safe levels with zero pH alerts for 30 days.",
                      icon: Icons.opacity_rounded,
                      unlocked: evolution.hasPerfectPhMonth,
                      badgeColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeTile(
                      context,
                      title: "Zero Alerts Week",
                      description: "No warnings or critical alerts triggered across all ponds in the past 7 days.",
                      icon: Icons.verified_user_rounded,
                      unlocked: evolution.hasZeroAlertsWeek,
                      badgeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool unlocked,
    required Color badgeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? badgeColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unlocked
                  ? badgeColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? badgeColor : Colors.grey.shade500,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: unlocked ? null : Colors.grey.shade500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                            size: 10,
                            color: unlocked ? Colors.green : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unlocked ? "Unlocked" : "Locked",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: unlocked ? Colors.green : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
