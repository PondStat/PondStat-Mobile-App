import 'dart:math' as math;
import 'package:flutter/material.dart';

class PondBackground extends StatefulWidget {
  const PondBackground({super.key});

  @override
  State<PondBackground> createState() => _PondBackgroundState();
}

class _PondBackgroundState extends State<PondBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColors = [colorScheme.surface, colorScheme.surfaceContainerHighest];

    final blob1Color = colorScheme.primary.withValues(
      alpha: isDark ? 0.04 : 0.10,
    );
    final blob2Color = colorScheme.secondary.withValues(
      alpha: isDark ? 0.04 : 0.08,
    );
    final blob3Color = colorScheme.tertiary.withValues(
      alpha: isDark ? 0.03 : 0.06,
    );

    final dotColor = colorScheme.onSurface;
    final dotOpacity = isDark ? 0.05 : 0.035;

    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: bgColors,
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = _controller.value * 2 * math.pi;

                final float1 = math.sin(t) * 20;
                final float2 = math.cos(t + math.pi / 4) * 25;
                final float3 = math.sin(t + math.pi / 2) * 15;

                return Stack(
                  children: [
                    Positioned(
                      top: size.height * -0.1,
                      left: size.width * -0.2,
                      child: Transform.translate(
                        offset: Offset(float2, float1),
                        child: _buildBlob(
                          size: size.width * 0.9,
                          color: blob1Color,
                        ),
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.3,
                      right: size.width * -0.3,
                      child: Transform.translate(
                        offset: Offset(float1, float3),
                        child: _buildBlob(
                          size: size.width * 0.8,
                          color: blob2Color,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: size.height * -0.15,
                      left: size.width * -0.15,
                      child: Transform.translate(
                        offset: Offset(float3, float2),
                        child: _buildBlob(
                          size: size.width * 1.0,
                          color: blob3Color,
                        ),
                      ),
                    ),
                    // God Rays (Sunlight shafts)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GodRaysPainter(
                          value: t,
                          color: isDark
                              ? Colors.cyan.shade100.withValues(alpha: 0.3)
                              : Colors.white,
                        ),
                      ),
                    ),
                    // Drifting Plankton Particles
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PlanktonPainter(
                          value: t,
                          color: colorScheme.primary.withValues(
                            alpha: isDark ? 0.35 : 0.4,
                          ),
                        ),
                      ),
                    ),
                    // Sea Bed (Sand, Rocks & Seagrass)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SeaBedPainter(
                          value: t,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: Opacity(
                opacity: dotOpacity,
                child: CustomPaint(
                  painter: _DotPatternPainter(color: dotColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size),
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;

  _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    const spacing = 40.0;
    const radius = 1.2;

    final int cols = (size.width / spacing).ceil();
    final int rows = (size.height / spacing).ceil();

    final double startX = (size.width - ((cols - 1) * spacing)) / 2;
    final double startY = (size.height - ((rows - 1) * spacing)) / 2;

    for (int i = 0; i < cols; i++) {
      for (int j = 0; j < rows; j++) {
        canvas.drawCircle(
          Offset(startX + (i * spacing), startY + (j * spacing)),
          radius,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _GodRaysPainter extends CustomPainter {
  final double value;
  final Color color;

  _GodRaysPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    const numBeams = 3;
    for (int i = 0; i < numBeams; i++) {
      final angleOffset = math.sin(value + i * 1.5) * 0.04;
      final baseWidth = size.width * 0.15;
      final startX = size.width * (0.2 + i * 0.3) + math.sin(value * 0.5 + i) * 30;

      final path = Path();
      final x1 = startX - baseWidth * 0.3;
      final x2 = startX + baseWidth * 0.3;
      final dx = size.height * math.tan(angleOffset - 0.08);
      final x3 = startX + dx + baseWidth * 2.2;
      final x4 = startX + dx - baseWidth * 2.2;

      path.moveTo(x1, 0);
      path.lineTo(x2, 0);
      path.lineTo(x3, size.height);
      path.lineTo(x4, size.height);
      path.close();

      paint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.10 + math.sin(value + i) * 0.03),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GodRaysPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _PlanktonPainter extends CustomPainter {
  final double value;
  final Color color;

  _PlanktonPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int numParticles = 20;
    for (int i = 0; i < numParticles; i++) {
      final double seedSpeed = 0.05 + (i * 0.013) % 0.08;
      final double seedAmplitude = 15.0 + (i * 7.7) % 25.0;
      final double seedFrequency = 1.0 + (i * 0.3) % 2.5;
      final double startX = (i * (size.width / numParticles)) + (i * 12.3) % 30.0;
      final double startY = (i * (size.height / numParticles)) + (i * 19.7) % 50.0;
      final double particleSize = 1.5 + (i * 1.3) % 3.0;

      final double elapsedSeconds = value / (2 * math.pi) * 15.0;
      double y = startY - (elapsedSeconds * 20.0 * seedSpeed * 10.0);
      y = y % size.height;
      if (y < 0) y += size.height;

      final double x = (startX + math.sin(value * seedFrequency + i) * seedAmplitude) % size.width;

      canvas.drawCircle(Offset(x, y), particleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PlanktonPainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.color != color;
  }
}

class _SeaBedPainter extends CustomPainter {
  final double value;
  final ColorScheme colorScheme;
  final bool isDark;

  _SeaBedPainter({
    required this.value,
    required this.colorScheme,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sandColor = isDark 
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.15)
        : colorScheme.primary.withValues(alpha: 0.08);
    final rockColor1 = isDark
        ? colorScheme.surfaceContainer.withValues(alpha: 0.3)
        : colorScheme.secondary.withValues(alpha: 0.12);
    final rockColor2 = isDark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
        : colorScheme.tertiary.withValues(alpha: 0.08);

    _drawSeagrass(canvas, size);

    final sandPaint = Paint()
      ..color = sandColor
      ..style = PaintingStyle.fill;

    final sandPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 45)
      ..quadraticBezierTo(size.width * 0.3, size.height - 60, size.width * 0.6, size.height - 40)
      ..quadraticBezierTo(size.width * 0.85, size.height - 25, size.width, size.height - 50)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(sandPath, sandPaint);

    final rockPaint1 = Paint()
      ..color = rockColor1
      ..style = PaintingStyle.fill;
    final rockPaint2 = Paint()
      ..color = rockColor2
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.15, size.height - 35),
        width: 110,
        height: 60,
      ),
      rockPaint1,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.82, size.height - 30),
        width: 130,
        height: 70,
      ),
      rockPaint2,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.9, size.height - 25),
        width: 80,
        height: 50,
      ),
      rockPaint1,
    );
  }

  void _drawSeagrass(Canvas canvas, Size size) {
    final grassColor = isDark
        ? colorScheme.primary.withValues(alpha: 0.18)
        : colorScheme.primary.withValues(alpha: 0.15);

    final paint = Paint()
      ..color = grassColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<Map<String, double>> blades = [
      {'x': size.width * 0.08, 'height': size.height * 0.18, 'phase': 0.0, 'width': 10},
      {'x': size.width * 0.14, 'height': size.height * 0.25, 'phase': 1.2, 'width': 12},
      {'x': size.width * 0.22, 'height': size.height * 0.15, 'phase': 0.5, 'width': 8},
      {'x': size.width * 0.72, 'height': size.height * 0.22, 'phase': 2.0, 'width': 10},
      {'x': size.width * 0.80, 'height': size.height * 0.28, 'phase': 0.8, 'width': 13},
      {'x': size.width * 0.88, 'height': size.height * 0.17, 'phase': 1.6, 'width': 9},
    ];

    for (final blade in blades) {
      final baseX = blade['x']!;
      final height = blade['height']!;
      final phase = blade['phase']!;
      final thickness = blade['width']!;

      paint.strokeWidth = thickness;

      final sway = math.sin(value + phase) * 20.0;

      final path = Path();
      path.moveTo(baseX, size.height - 10);
      
      final cpX = baseX + sway * 0.4;
      final cpY = size.height - height * 0.5;
      
      final tipX = baseX + sway;
      final tipY = size.height - height;

      path.quadraticBezierTo(cpX, cpY, tipX, tipY);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SeaBedPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.isDark != isDark;
  }
}
