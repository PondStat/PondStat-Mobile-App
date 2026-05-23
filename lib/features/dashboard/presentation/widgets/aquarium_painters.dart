import 'dart:math' as math;
import 'package:flutter/material.dart';

// ==================== ECOSYSTEM MODELS ====================

class NeonFish {
  Offset position;
  double speed;
  double angle;
  double phaseOffset;
  final Color color;

  NeonFish({
    required this.position,
    required this.speed,
    required this.angle,
    required this.phaseOffset,
    required this.color,
  });
}

class FoodPellet {
  Offset position;
  double speedY;
  double driftPhase;
  double size;
  double opacity = 1.0;
  bool settled = false;
  int settleTicks = 0;

  FoodPellet({
    required this.position,
    required this.speedY,
    required this.driftPhase,
    required this.size,
  });
}

class AlgaeParticle {
  Offset position;
  double speedX;
  double speedY;
  double angle;
  double size;

  AlgaeParticle({
    required this.position,
    required this.speedX,
    required this.speedY,
    required this.angle,
    required this.size,
  });
}

class PlanktonParticle {
  Offset position;
  double speedY;
  double size;
  double phaseOffset;

  PlanktonParticle({
    required this.position,
    required this.speedY,
    required this.size,
    required this.phaseOffset,
  });
}

class NeonJellyfish {
  Offset position;
  double speed;
  double phaseOffset;
  final Color color;
  final double size;

  NeonJellyfish({
    required this.position,
    required this.speed,
    required this.phaseOffset,
    required this.color,
    required this.size,
  });
}

class VibeBubble {
  Offset position;
  double speedY;
  double size;
  double phaseOffset;

  VibeBubble({
    required this.position,
    required this.speedY,
    required this.size,
    required this.phaseOffset,
  });
}

// ==================== CUSTOM PAINTERS ====================

// 1. Shimmering Wave God Rays Custom Painter
class GodRaysPainter extends CustomPainter {
  final double timePhase;
  final bool isNightMode;
  final String statusMood;

  GodRaysPainter({
    required this.timePhase,
    required this.isNightMode,
    required this.statusMood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Brightness modifiers driven by parameter health
    double brightnessMod = statusMood == 'critical' ? 0.35 : (statusMood == 'warning' ? 0.65 : 1.0);

    final rayColor = isNightMode
        ? const Color(0xFF64B5F6).withValues(alpha: 0.04 * brightnessMod)
        : const Color(0xFFE0F7FA).withValues(alpha: 0.08 * brightnessMod);

    final double rayCount = statusMood == 'critical' ? 2 : 4;

    for (int i = 0; i < rayCount; i++) {
      final double widthPhase = math.sin(timePhase * 0.8 + i * 1.5) * 15.0;
      final double baseWidth = 50.0 + i * 20.0 + widthPhase;
      final double angleOffset = math.sin(timePhase * 0.4 + i * 2.0) * 0.05;

      final Path path = Path()
        ..moveTo(-50, -50)
        ..lineTo(baseWidth, -50)
        ..lineTo(baseWidth * 2.5 + math.cos(angleOffset) * 200.0, size.height + 50)
        ..lineTo((baseWidth - 50) * 2.5 + math.cos(angleOffset) * 200.0, size.height + 50)
        ..close();

      canvas.drawPath(path, paint..color = rayColor);
    }
  }

  @override
  bool shouldRepaint(covariant GodRaysPainter oldDelegate) {
    return oldDelegate.timePhase != timePhase ||
        oldDelegate.isNightMode != isNightMode ||
        oldDelegate.statusMood != statusMood;
  }
}

// 2. Schooling Neon Tetra Fish Custom Painter
class SchoolFishPainter extends CustomPainter {
  final List<NeonFish> fishList;
  final double timePhase;

  SchoolFishPainter({
    required this.fishList,
    required this.timePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    for (final fish in fishList) {
      canvas.save();
      canvas.translate(fish.position.dx, fish.position.dy);
      canvas.rotate(fish.angle);

      const double length = 17.0;
      const double width = 5.6;

      // Glow bioluminescence shadow
      paint.color = fish.color.withValues(alpha: 0.20);
      canvas.drawCircle(Offset.zero, 10, paint);

      // Glowing body
      paint.shader = LinearGradient(
        colors: [fish.color, fish.color.withValues(alpha: 0.30)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(const Rect.fromLTWH(-length / 2, -width / 2, length, width));
      paint.style = PaintingStyle.fill;

      final bodyPath = Path()
        ..moveTo(length / 2, 0)
        ..quadraticBezierTo(0, -width, -length / 2, 0)
        ..quadraticBezierTo(0, width, length / 2, 0)
        ..close();
      canvas.drawPath(bodyPath, paint);

      // Swaying Tail
      paint.shader = null;
      paint.color = fish.color;
      final double tailSway = math.sin(timePhase * 16.0 + fish.phaseOffset) * 3.8;
      final tailPath = Path()
        ..moveTo(-length / 2, 0)
        ..lineTo(-length / 2 - 5, tailSway - 3)
        ..lineTo(-length / 2 - 2.5, 0)
        ..lineTo(-length / 2 - 5, tailSway + 3)
        ..close();
      canvas.drawPath(tailPath, paint);

      paint.color = Colors.white;
      canvas.drawCircle(const Offset(length / 3.2, -0.8), 0.9, paint);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant SchoolFishPainter oldDelegate) {
    return oldDelegate.timePhase != timePhase || oldDelegate.fishList.length != fishList.length;
  }
}

// 3. Bioluminescent Pulsating Jellyfish Custom Painter
class JellyfishPainter extends CustomPainter {
  final List<NeonJellyfish> jellyfishList;
  final double timePhase;

  JellyfishPainter({
    required this.jellyfishList,
    required this.timePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    for (final jelly in jellyfishList) {
      canvas.save();
      canvas.translate(jelly.position.dx, jelly.position.dy);

      // Rhythmic bell contraction scale
      final double contract = 1.0 - 0.16 * math.sin(timePhase * 2.6 + jelly.phaseOffset);
      canvas.scale(1.0, contract);

      final double radius = jelly.size;

      // Glow circle
      paint.color = jelly.color.withValues(alpha: 0.15);
      canvas.drawCircle(Offset.zero, radius * 1.5, paint);

      // 1. Draw glowing translucent cap (dome)
      paint.shader = LinearGradient(
        colors: [jelly.color, jelly.color.withValues(alpha: 0.15)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-radius, -radius, radius * 2, radius * 2));

      final capPath = Path()
        ..moveTo(-radius, 0)
        ..cubicTo(-radius, -radius * 1.3, radius, -radius * 1.3, radius, 0)
        ..quadraticBezierTo(0, radius * 0.3, -radius, 0)
        ..close();
      canvas.drawPath(capPath, paint);
      paint.shader = null;

      // 2. Draw organic dangling wavy tentacles below
      paint.color = jelly.color.withValues(alpha: 0.4);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;

      for (int i = 0; i < 3; i++) {
        final double tentacleX = -radius * 0.5 + (i * radius * 0.5);
        final double swayOffset = math.sin(timePhase * 4.0 + jelly.phaseOffset + (i * 1.5)) * (radius * 0.35);

        final Path tentaclePath = Path()
          ..moveTo(tentacleX, 0)
          ..quadraticBezierTo(
            tentacleX + swayOffset * 0.5,
            radius * 0.8,
            tentacleX + swayOffset,
            radius * 1.8,
          );
        canvas.drawPath(tentaclePath, paint);
      }

      paint.style = PaintingStyle.fill;
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant JellyfishPainter oldDelegate) {
    return oldDelegate.timePhase != timePhase || oldDelegate.jellyfishList.length != jellyfishList.length;
  }
}

// 4. Swaying Seaweed Forest with Parallax Depth and Seabed Sand Dunes
class SeaweedPainter extends CustomPainter {
  final double timePhase;
  final bool isNightMode;
  final String statusMood;

  SeaweedPainter({
    required this.timePhase,
    required this.isNightMode,
    required this.statusMood,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    // Organic sand dunes
    final sandPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: isNightMode
            ? [const Color(0xFF041220), const Color(0xFF010A14)]
            : (statusMood == 'critical'
                ? [const Color(0xFF1B2F2A), const Color(0xFF0F1B18)]
                : [const Color(0xFF004D40), const Color(0xFF00251A)]),
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, size.height - 40, size.width, 40));

    final sandPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height - 25)
      ..quadraticBezierTo(size.width * 0.35, size.height - 42, size.width * 0.7, size.height - 22)
      ..quadraticBezierTo(size.width * 0.85, size.height - 14, size.width, size.height - 28)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(sandPath, sandPaint);

    final seaweedColorLight = isNightMode
        ? const Color(0xFF0F3820).withValues(alpha: 0.8)
        : (statusMood == 'critical'
            ? const Color(0xFF2E4F2E).withValues(alpha: 0.75) // murky olive
            : const Color(0xFF2E7D32).withValues(alpha: 0.85));

    final seaweedColorDark = isNightMode
        ? const Color(0xFF05170B).withValues(alpha: 0.9)
        : const Color(0xFF0D320D).withValues(alpha: 0.95);

    // ==================== LAYER 1: FAR BACKGROUND PARALLAX KELP ====================
    final List<double> parallaxXPositions = [
      size.width * 0.15,
      size.width * 0.38,
      size.width * 0.55,
      size.width * 0.76,
      size.width * 0.88,
    ];

    for (int i = 0; i < parallaxXPositions.length; i++) {
      final double rootX = parallaxXPositions[i];
      final double height = 100.0 + (i % 2) * 50.0 + (math.sin(i * 5.0).abs() * 25.0);
      final double rootY = size.height - 20;

      // Slower sway cycle for background depth parallax
      final double sway = math.sin(timePhase * 0.7 + i * 2.5) * (14.0 + i * 2.0);

      paint.shader = LinearGradient(
        colors: [seaweedColorLight.withValues(alpha: 0.32), seaweedColorDark.withValues(alpha: 0.32)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(rootX - 8, rootY - height, 16, height));

      final Path path = Path()
        ..moveTo(rootX - 6, rootY)
        ..quadraticBezierTo(rootX - 3 + sway * 0.4, rootY - height * 0.5, rootX + sway, rootY - height)
        ..quadraticBezierTo(rootX + 3 + sway * 0.4, rootY - height * 0.5, rootX + 6, rootY)
        ..close();
      canvas.drawPath(path, paint);
    }

    // ==================== LAYER 2: MAIN MIDGROUND SEAWEED ====================
    final List<double> startXPositions = [
      size.width * 0.08,
      size.width * 0.22,
      size.width * 0.45,
      size.width * 0.62,
      size.width * 0.84,
      size.width * 0.93,
    ];

    for (int i = 0; i < startXPositions.length; i++) {
      final double rootX = startXPositions[i];
      final double height = 130.0 + (i % 3) * 60.0 + (math.sin(i * 10.0).abs() * 30.0);
      final double rootY = size.height - 20;

      // Standard organic sway
      final double sway = math.sin(timePhase * 1.5 + i * 2.0) * (20.0 + i * 4.0);

      paint.shader = LinearGradient(
        colors: [seaweedColorLight, seaweedColorDark],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(rootX - 10, rootY - height, 20, height));

      final Path path = Path()
        ..moveTo(rootX - 8, rootY)
        ..quadraticBezierTo(rootX - 4 + sway * 0.4, rootY - height * 0.5, rootX + sway, rootY - height)
        ..quadraticBezierTo(rootX + 4 + sway * 0.4, rootY - height * 0.5, rootX + 8, rootY)
        ..close();
      canvas.drawPath(path, paint);

      // Light center rib line
      paint.shader = null;
      paint.color = Colors.white.withValues(alpha: 0.08);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;

      final Path ribPath = Path()
        ..moveTo(rootX, rootY)
        ..quadraticBezierTo(rootX + sway * 0.4, rootY - height * 0.5, rootX + sway, rootY - height);
      canvas.drawPath(ribPath, paint);
      paint.style = PaintingStyle.fill;
    }
  }

  @override
  bool shouldRepaint(covariant SeaweedPainter oldDelegate) {
    return oldDelegate.timePhase != timePhase ||
        oldDelegate.isNightMode != isNightMode ||
        oldDelegate.statusMood != statusMood;
  }
}

// 5. Plankton, Algae, Food Pellets, and Vibe Mode Bubbles Painter
class EcosystemParticlesPainter extends CustomPainter {
  final List<FoodPellet> foodPellets;
  final List<AlgaeParticle> algaeParticles;
  final List<PlanktonParticle> planktonList;
  final List<VibeBubble> vibeBubbles;
  final double timePhase;

  EcosystemParticlesPainter({
    required this.foodPellets,
    required this.algaeParticles,
    required this.planktonList,
    required this.vibeBubbles,
    required this.timePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // 1. Draw Rising Translucent Plankton Specs
    paint.color = Colors.white.withValues(alpha: 0.16);
    paint.style = PaintingStyle.fill;
    for (final plankton in planktonList) {
      canvas.drawCircle(plankton.position, plankton.size, paint);
    }

    // 2. Draw Floaty Green Algae Particles (murky clues)
    for (final algae in algaeParticles) {
      canvas.save();
      canvas.translate(algae.position.dx, algae.position.dy);
      canvas.rotate(algae.angle);

      // Draw a tiny oval leaf
      paint.color = const Color(0xFF689F38).withValues(alpha: 0.42);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: algae.size * 2, height: algae.size),
        paint,
      );
      canvas.restore();
    }

    // 3. Draw Vibe Mode Bubble Streams
    for (final bubble in vibeBubbles) {
      final pos = bubble.position;
      final radius = bubble.size;

      // Draw bubble outline
      paint.color = Colors.white.withValues(alpha: 0.22);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.0;
      canvas.drawCircle(pos, radius, paint);

      // Draw bubble glossy highlight shine dot
      paint.color = Colors.white.withValues(alpha: 0.38);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        pos - Offset(radius * 0.3, radius * 0.3),
        radius * 0.2,
        paint,
      );
    }

    // 4. Draw Sinking & Settled Food Pellets
    for (final pellet in foodPellets) {
      final pos = pellet.position;
      final radius = pellet.size;

      // outer glowing halo
      paint.color = const Color(0xFF8D6E63).withValues(alpha: 0.22 * pellet.opacity);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius * 1.6, paint);

      // main solid pellet core
      paint.shader = LinearGradient(
        colors: [const Color(0xFF8D6E63), const Color(0xFF5D4037)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: pos, radius: radius));
      canvas.drawCircle(pos, radius, paint);
      paint.shader = null;
    }
  }

  @override
  bool shouldRepaint(covariant EcosystemParticlesPainter oldDelegate) {
    return oldDelegate.timePhase != timePhase ||
        oldDelegate.foodPellets.length != foodPellets.length ||
        oldDelegate.algaeParticles.length != algaeParticles.length ||
        oldDelegate.vibeBubbles.length != vibeBubbles.length;
  }
}
