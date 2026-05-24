import 'dart:math' show sin, pi, min;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:pondstat/core/router/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/streak_provider.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/streak_flame.dart';
import 'package:pondstat/features/monitoring/data/pond_health_provider.dart';
import 'package:pondstat/core/theme/pond_status_colors.dart';

class PondListCard extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final String userRole;
  final DateTime createdAt;
  final int targetCulturePeriodDays;

  const PondListCard({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.userRole,
    required this.createdAt,
    required this.targetCulturePeriodDays,
  });

  @override
  ConsumerState<PondListCard> createState() => _PondListCardState();
}

class _PondListCardState extends ConsumerState<PondListCard>
    with TickerProviderStateMixin {
  bool _isNavigating = false;
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _navigateToMonitoring(BuildContext context) async {
    if (_isNavigating) return;

    setState(() {
      _isNavigating = true;
    });

    await context.push(
      AppRoutes.pondPath(widget.pondId),
      extra: <String, dynamic>{
        'pondName': widget.pondName,
        'userRole': widget.userRole,
        'species': widget.species,
        'createdAt': widget.createdAt,
        'targetCulturePeriodDays': widget.targetCulturePeriodDays,
      },
    );

    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final currentDay = DateTime.now().difference(widget.createdAt).inDays;
    // Cap current day to 0 if it's somehow negative (e.g. timezones)
    final displayDay = currentDay < 0 ? 0 : currentDay;

    // Calculate progress clamped [0.0, 1.0]
    final totalDays = widget.targetCulturePeriodDays > 0 ? widget.targetCulturePeriodDays : 90;
    final double progress = (displayDay / totalDays).clamp(0.0, 1.0);

    // Deterministic organic corners based on pond ID to mimic natural shoreline variance
    final hash = widget.pondId.hashCode;
    final double tl = 28.0 + (hash % 13);
    final double tr = 20.0 + ((hash >> 2) % 13);
    final double bl = 22.0 + ((hash >> 4) % 13);
    final double br = 30.0 + ((hash >> 6) % 13);
    
    final customBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(tl),
      topRight: Radius.circular(tr),
      bottomLeft: Radius.circular(bl),
      bottomRight: Radius.circular(br),
    );

    // Basin background gradients representing beautiful aquatic colors
    final basinGradient = isDark
        ? LinearGradient(
            colors: [
              const Color(0xFF0B132B), // Deep Space Blue
              const Color(0xFF0F3A4B).withValues(alpha: 0.3), // Mysterious Aquatic Abyss
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              const Color(0xFFF0F9FF), // Pristine light blue
              const Color(0xFFE0F2FE), // Pure water light sky-blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final border = Border.all(
      color: isDark 
          ? colorScheme.primary.withValues(alpha: 0.18) 
          : colorScheme.primary.withValues(alpha: 0.08),
      width: 1.5,
    );

    return Semantics(
      button: true,
      label:
          "${widget.pondName} pond. Species: ${widget.species}. Your role is ${widget.userRole}. Day $displayDay of ${widget.targetCulturePeriodDays}.",
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          gradient: basinGradient,
          borderRadius: customBorderRadius,
          border: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: isDark ? 0.05 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: customBorderRadius,
          child: Stack(
            children: [
              // Dynamic liquid water and floating bubbles painter
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) => CustomPaint(
                    painter: _PondWaterPainter(
                      progress: progress,
                      wavePhase: _waveController.value,
                      primaryColor: colorScheme.primary,
                      secondaryColor: colorScheme.secondary,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
              // Card interactive overlay content
              Material(
                color: Colors.transparent,
                borderRadius: customBorderRadius,
                child: InkWell(
                  borderRadius: customBorderRadius,
                  onTap: () => _navigateToMonitoring(context),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        // Micro circular pool (mini-pond) for species icon
                        Container(
                          height: 56,
                          width: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colorScheme.secondary, colorScheme.primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'pond-icon-${widget.pondId}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: FaIcon(
                                _getSpeciesIcon(widget.species),
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.pondName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        letterSpacing: -0.3,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ref.watch(pondStreakProvider(widget.pondId)).when(
                                        data: (streak) => StreakFlame(streak: streak, size: 14),
                                        error: (err, stack) => const SizedBox.shrink(),
                                        loading: () => const SizedBox.shrink(),
                                      ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  FaIcon(
                                    _getSpeciesIcon(widget.species),
                                    size: 13,
                                    color: colorScheme.onSurfaceVariant.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      widget.species,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Day $displayDay of ${widget.targetCulturePeriodDays}',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        ref.watch(pondHealthScoreProvider(PondHealthParam(
                          pondId: widget.pondId,
                          species: widget.species,
                        ))).when(
                              data: (health) => _buildHealthGauge(
                                context,
                                health.score,
                                health,
                                colorScheme,
                                isDark,
                              ),
                              error: (err, stack) => _buildHealthGauge(
                                context,
                                100.0,
                                null,
                                colorScheme,
                                isDark,
                                hasError: true,
                              ),
                              loading: () => _buildHealthGaugeLoading(
                                context,
                                colorScheme,
                                isDark,
                              ),
                            ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildRoleBadge(colorScheme, isDark),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: isDark 
                                    ? Colors.white.withValues(alpha: 0.08) 
                                    : Colors.white.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark 
                                      ? Colors.white.withValues(alpha: 0.05) 
                                      : Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                size: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(ColorScheme colorScheme, bool isDark) {
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (widget.userRole.toLowerCase()) {
      case 'owner':
        bgColor = isDark
            ? Colors.green.withValues(alpha: 0.15)
            : Colors.green.shade50;
        borderColor = isDark
            ? Colors.green.withValues(alpha: 0.3)
            : Colors.green.shade200;
        textColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        break;
      case 'editor':
        bgColor = isDark
            ? Colors.blue.withValues(alpha: 0.15)
            : Colors.blue.shade50;
        borderColor = isDark
            ? Colors.blue.withValues(alpha: 0.3)
            : Colors.blue.shade200;
        textColor = isDark
            ? Colors.blue.shade300
            : Colors.blue.shade700;
        break;
      case 'viewer':
      default:
        bgColor = isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade100;
        borderColor = isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey.shade300;
        textColor = isDark ? Colors.white70 : Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Text(
        widget.userRole.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  IconData _getSpeciesIcon(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('tilapia') || lower.contains('fish')) {
      return FontAwesomeIcons.fish;
    }
    if (lower.contains('shrimp') ||
        lower.contains('prawn') ||
        lower.contains('vannamei')) {
      return FontAwesomeIcons.shrimp;
    }
    return FontAwesomeIcons.droplet;
  }

  Color _getHealthColor(double score, BuildContext context) {
    if (score < 0) return Colors.grey;
    if (score >= 80) return context.pondColors.healthy;
    if (score >= 50) return context.pondColors.warning;
    return context.pondColors.critical;
  }

  String _getTooltipMessage(double score, PondHealthScore? health, bool hasError) {
    if (hasError) return "Error loading health score";
    if (score < 0 || health == null) return "No parameters recorded yet";

    final warningCount = health.warningParameters.length;
    final criticalCount = health.criticalParameters.length;

    if (warningCount == 0 && criticalCount == 0) {
      return "All parameters are safe ($score%)";
    }

    final List<String> issues = [];
    if (criticalCount > 0) {
      issues.add("$criticalCount CRITICAL (${health.criticalParameters.join(', ')})");
    }
    if (warningCount > 0) {
      issues.add("$warningCount WARNING (${health.warningParameters.join(', ')})");
    }
    return "Health Score: ${score.toInt()}%\nIssues:\n• ${issues.join('\n• ')}";
  }

  Widget _buildHealthGauge(
    BuildContext context,
    double score,
    PondHealthScore? healthScoreData,
    ColorScheme colorScheme,
    bool isDark, {
    bool hasError = false,
  }) {
    final statusColor = hasError ? colorScheme.error : _getHealthColor(score, context);

    return Tooltip(
      message: _getTooltipMessage(score, healthScoreData, hasError),
      triggerMode: TooltipTriggerMode.tap,
      showDuration: const Duration(seconds: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: CustomPaint(
          painter: HealthGaugePainter(
            score: score,
            color: statusColor,
            isDark: isDark,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasError ? "N/A" : (score < 0 ? "—" : "${score.toInt()}"),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                    height: 1.1,
                  ),
                ),
                Text(
                  "HEALTH",
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHealthGaugeLoading(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return SizedBox(
      width: 50,
      height: 50,
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _PondWaterPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final Color primaryColor;
  final Color secondaryColor;
  final bool isDark;

  _PondWaterPainter({
    required this.progress,
    required this.wavePhase,
    required this.primaryColor,
    required this.secondaryColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Height bounding: minimum 25% water visual base, scaling up to 80% visual max fill
    final double minHeight = size.height * 0.25;
    final double maxHeight = size.height * 0.80;
    final double waterHeight = minHeight + (maxHeight - minHeight) * progress;

    final paintWave1 = Paint()
      ..shader = LinearGradient(
        colors: [
          secondaryColor.withValues(alpha: isDark ? 0.22 : 0.28),
          primaryColor.withValues(alpha: isDark ? 0.08 : 0.12),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTRB(0, size.height - waterHeight, size.width, size.height));

    final paintWave2 = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: isDark ? 0.26 : 0.32),
          secondaryColor.withValues(alpha: isDark ? 0.12 : 0.16),
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTRB(0, size.height - waterHeight, size.width, size.height));

    // Wave phase shift: sin oscillation drives crests left↔right smoothly
    final double phase = sin(wavePhase * 2 * pi);
    final double amp = size.height * 0.04; // 4% amplitude — subtle

    // First back layer wave
    final path1 = Path();
    path1.moveTo(0, size.height);
    path1.lineTo(0, size.height - waterHeight + 10 + amp * phase);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height - waterHeight - 12 - amp * phase,
      size.width * 0.5,
      size.height - waterHeight + amp * phase * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      size.height - waterHeight + 12 + amp * phase,
      size.width,
      size.height - waterHeight - 8 - amp * phase * 0.5,
    );
    path1.lineTo(size.width, size.height);
    path1.close();
    canvas.drawPath(path1, paintWave1);

    // Second front layer wave (phase-inverted for natural cross-swell effect)
    final path2 = Path();
    path2.moveTo(0, size.height);
    path2.lineTo(0, size.height - waterHeight - amp * phase * 0.8);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height - waterHeight + 15 + amp * phase,
      size.width * 0.65,
      size.height - waterHeight - 10 - amp * phase * 0.6,
    );
    path2.quadraticBezierTo(
      size.width * 0.85,
      size.height - waterHeight - 2 + amp * phase * 0.4,
      size.width,
      size.height - waterHeight + 5 + amp * phase * 0.7,
    );
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paintWave2);

    // Subtle background bubble details floating in the liquid area
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.12 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final bubbleFilledPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.04 : 0.06)
      ..style = PaintingStyle.fill;

    final double waterTop = size.height - waterHeight;
    final List<Offset> bubbleOffsets = [
      Offset(size.width * 0.15, waterTop + waterHeight * 0.6),
      Offset(size.width * 0.35, waterTop + waterHeight * 0.3),
      Offset(size.width * 0.55, waterTop + waterHeight * 0.75),
      Offset(size.width * 0.72, waterTop + waterHeight * 0.45),
      Offset(size.width * 0.88, waterTop + waterHeight * 0.2),
    ];
    final List<double> bubbleRadii = [3.5, 6.0, 2.5, 5.0, 4.0];

    for (int i = 0; i < bubbleOffsets.length; i++) {
      final center = bubbleOffsets[i];
      final radius = bubbleRadii[i];
      
      if (center.dy + radius < size.height && center.dy - radius > waterTop) {
        canvas.drawCircle(center, radius, bubbleFilledPaint);
        canvas.drawCircle(center, radius, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PondWaterPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.isDark != isDark;
  }
}

class HealthGaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final bool isDark;

  HealthGaugePainter({
    required this.score,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track Paint
    final trackPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    // Progress Paint
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    // Glow Paint
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    // Draw track
    canvas.drawCircle(center, radius, trackPaint);

    if (score > 0) {
      // Draw progress arc (start from top: -pi/2)
      final double sweepAngle = (score / 100.0) * 2 * pi;
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, glowPaint);
      canvas.drawArc(rect, -pi / 2, sweepAngle, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant HealthGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

