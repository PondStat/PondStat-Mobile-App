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
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColors = isDark
        ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
        : const [Color(0xFFEAF4FF), Color(0xFFF7F9FC)];

    final blob1Color = isDark
        ? const Color(0xFF38BDF8).withValues(alpha: 0.04)
        : const Color(0xFF0077C2).withValues(alpha: 0.10);

    final blob2Color = isDark
        ? const Color(0xFF818CF8).withValues(alpha: 0.04)
        : const Color(0xFF0099E5).withValues(alpha: 0.08);

    final blob3Color = isDark
        ? const Color(0xFF0EA5E9).withValues(alpha: 0.03)
        : const Color(0xFF0077C2).withValues(alpha: 0.07);

    final dotColor = isDark ? Colors.white : Colors.black;
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
                      top: (size.height * -0.1) + float1,
                      left: (size.width * -0.2) + float2,
                      child: _buildBlob(
                        size: size.width * 0.9,
                        color: blob1Color,
                      ),
                    ),
                    Positioned(
                      top: (size.height * 0.3) + float3,
                      right: (size.width * -0.3) + float1,
                      child: _buildBlob(
                        size: size.width * 0.8,
                        color: blob2Color,
                      ),
                    ),
                    Positioned(
                      bottom: (size.height * -0.15) + float2,
                      left: (size.width * -0.15) + float3,
                      child: _buildBlob(
                        size: size.width * 1.0,
                        color: blob3Color,
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
        color: color,
        borderRadius: BorderRadius.circular(size),
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 10)],
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
