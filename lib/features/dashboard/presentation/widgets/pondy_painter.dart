import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pondy_companion_models.dart';

class PondyPainter extends CustomPainter {
  final Offset pondyPosition;
  final bool facingLeft;
  final String activeState;
  final String statusMood;
  final List<FeedPellet> pellets;
  final List<BubbleParticle> bubbles;
  final List<HappyEmoji> happyEmojis;
  final Offset lookTarget;
  final double timePhase;
  final double tiltAngle;
  final List<SwimRipple> swimRipples;

  PondyPainter({
    required this.pondyPosition,
    required this.facingLeft,
    required this.activeState,
    required this.statusMood,
    required this.pellets,
    required this.bubbles,
    required this.happyEmojis,
    required this.lookTarget,
    required this.timePhase,
    required this.tiltAngle,
    required this.swimRipples,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    // 0. Draw Trailing Swim Ripples (Propagating fluid wake circles in the background)
    for (final ripple in swimRipples) {
      paint.shader = null;
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.6 * ripple.life;
      paint.color = Colors.white.withValues(alpha: 0.16 * ripple.life);
      
      final double radius = ripple.initialRadius + (1.0 - ripple.life) * 26.0;
      canvas.drawCircle(ripple.position, radius, paint);
    }
    paint.style = PaintingStyle.fill;

    // 1. Draw Food Pellets (Sinking circles with organic feed brown shader)
    for (final pellet in pellets) {
      paint.shader = const RadialGradient(
        colors: [Color(0xFF8D6E63), Color(0xFF5D4037)],
      ).createShader(Rect.fromCircle(center: pellet.position, radius: pellet.size));
      canvas.drawCircle(pellet.position, pellet.size, paint);
      
      // Highlight rim
      paint.shader = null;
      paint.style = PaintingStyle.stroke;
      paint.color = Colors.white24;
      paint.strokeWidth = 1.0;
      canvas.drawCircle(pellet.position, pellet.size, paint);
      paint.style = PaintingStyle.fill;
    }

    // 2. Draw Air Bubbles
    for (final bubble in bubbles) {
      paint.shader = null;
      paint.color = Colors.white.withValues(alpha: 0.3 * bubble.life);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 1.2;
      canvas.drawCircle(bubble.position, bubble.size, paint);

      // Soft light reflection accent in bubble
      paint.color = Colors.white.withValues(alpha: 0.4 * bubble.life);
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(bubble.position.dx - bubble.size * 0.3, bubble.position.dy - bubble.size * 0.3),
        bubble.size * 0.25,
        paint,
      );
    }

    // 3. Draw Happy Emojis
    for (final happy in happyEmojis) {
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: happy.emoji,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withValues(alpha: happy.life),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(happy.position.dx - textPainter.width / 2, happy.position.dy),
      );
    }

    // 4. Render Pondy the Turtle!
    _drawTurtle(canvas, paint);
  }

  void _drawTurtle(Canvas canvas, Paint paint) {
    canvas.save();
    canvas.translate(pondyPosition.dx, pondyPosition.dy);

    // Apply horizontal flip rotation based on swim direction
    if (facingLeft) {
      canvas.scale(-1, 1);
    }

    // Apply smooth lean/tilt angle for biological pitch/yaw rotation!
    canvas.rotate(tiltAngle);

    // Continuous slow breathing expansion (2% scale change)
    final double breath = 1.0 + 0.02 * math.sin(timePhase * 2.2);
    canvas.scale(breath, breath);

    // If tickled, apply high-speed joyful wiggling and squeezing scale effects
    if (activeState == 'tickled') {
      canvas.rotate(math.sin(timePhase * 25.0) * 0.4);
      canvas.scale(
        1.0 + 0.1 * math.sin(timePhase * 30.0),
        1.0 - 0.1 * math.sin(timePhase * 30.0),
      );
    }

    // Dynamic 3D lighting direction: light comes from top-left (relative to the screen)
    // If the turtle is flipped horizontally, the local X coordinates flip, so we adapt the shading phase!
    final double lightDirX = facingLeft ? -1.0 : 1.0;

    // Rowing animation cycles for limbs
    final bool isSwim = activeState == 'swimming';
    final double cycleSpeed = isSwim ? 12.0 : 5.0;
    
    // Wave phase driving flipper rowing
    final double rowPhase = timePhase * cycleSpeed;
    final double flipperRow = math.sin(rowPhase) * 0.35;

    // Tail wiggle speed factor (wiggles much faster when swimming quickly)
    final double tailSpeedFactor = isSwim ? (pellets.isNotEmpty ? 1.6 : 0.8) : 0.35;
    final double tailWiggle = math.sin(timePhase * 12.0 * tailSpeedFactor) * 0.22 * tailSpeedFactor;

    // 3D Foreshortening scales (scaling local axes as limbs flap forward/closer & sweep back/away)
    final double frontScaleX = 1.0 + 0.16 * math.cos(rowPhase);
    final double frontScaleY = 1.0 + 0.10 * math.sin(rowPhase);
    
    final double rearScaleX = 1.0 - 0.12 * math.cos(rowPhase);
    final double rearScaleY = 1.0 - 0.08 * math.sin(rowPhase);

    // Dynamic Chiaroscuro Gradient Shading factors (brighter when forward/catching light, darker when sweeping back/shadowed)
    final double lowerFrontShade = 0.5 + 0.3 * math.sin(rowPhase);
    final double upperFrontShade = 0.7 + 0.3 * math.cos(rowPhase);
    final double lowerRearShade = 0.4 - 0.25 * math.cos(rowPhase);
    final double upperRearShade = 0.6 - 0.25 * math.sin(rowPhase);

    // A. Draw LOWER Background Limbs (underneath the carapace in canvas order)
    
    // 1. Lower Front Flipper
    canvas.save();
    canvas.translate(12, 8);
    canvas.rotate(-flipperRow + 0.3);
    canvas.scale(frontScaleX, frontScaleY);
    
    final lowerFrontColorLight = Color.lerp(const Color(0xFF1B5E20), const Color(0xFF4CAF50), lowerFrontShade)!;
    final lowerFrontColorDark = Color.lerp(const Color(0xFF0C2E0C), const Color(0xFF1B5E20), lowerFrontShade * 0.5)!;
    final limbPaintBgFront = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [lowerFrontColorLight, lowerFrontColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, 22, 22));

    final lowerFrontFlipperPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(18, 16, 22, 22)
      ..quadraticBezierTo(12, 32, -4, 12)
      ..close();
    canvas.drawPath(lowerFrontFlipperPath, limbPaintBgFront);
    canvas.restore();

    // 2. Lower Rear Leg
    canvas.save();
    canvas.translate(-16, 8);
    canvas.rotate(flipperRow * 0.4 + 0.2);
    canvas.scale(rearScaleX, rearScaleY);
    
    final lowerRearColorLight = Color.lerp(const Color(0xFF0F3810), const Color(0xFF2E7D32), lowerRearShade)!;
    final lowerRearColorDark = const Color(0xFF051705);
    final limbPaintBgRear = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [lowerRearColorLight, lowerRearColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(-15, 0, 15, 10));

    final lowerRearLegPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-10, 12, -15, 10)
      ..quadraticBezierTo(-10, 2, 0, 0)
      ..close();
    canvas.drawPath(lowerRearLegPath, limbPaintBgRear);
    canvas.restore();

    // B. Draw Cute Pointy Tail (wiggles back and forth with soft shadow)
    canvas.save();
    canvas.translate(-24, 0);
    final tailColorLight = Color.lerp(const Color(0xFF1B5E20), const Color(0xFF388E3C), 0.5 + 0.5 * tailWiggle)!;
    final tailPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [tailColorLight, const Color(0xFF0C2E0C)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(-18, -3, 18, 6));

    final tailPath = Path()
      ..moveTo(0, -3)
      ..quadraticBezierTo(-14, tailWiggle * 25, -18, tailWiggle * 25)
      ..quadraticBezierTo(-10, 3, 0, 3)
      ..close();
    canvas.drawPath(tailPath, tailPaint);
    canvas.restore();

    // C. Draw Head & Neck (catching dynamic sunlight with neck lag inertia)
    canvas.save();
    canvas.translate(-tiltAngle * 3.0, -tiltAngle.abs() * 1.5);
    final double headLightFactor = 0.5 + 0.3 * math.sin(timePhase * 2.5) * lightDirX;
    final headColorLight = Color.lerp(const Color(0xFF81C784), const Color(0xFFC8E6C9), headLightFactor)!;
    final headColorDark = Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), (1.0 - headLightFactor))!;
    final headPaint = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [headColorLight, headColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: const Offset(25, -3), radius: 11));
    
    // Draw cute rounded neck/head protrusion
    canvas.drawOval(Rect.fromCenter(center: const Offset(25, -3), width: 22, height: 18), headPaint);
    canvas.restore();

    // D. Draw FOREGROUND Upper Limbs (on top of carapace)
    
    // 1. Upper Front Flipper
    canvas.save();
    canvas.translate(12, -8);
    canvas.rotate(flipperRow - 0.3);
    canvas.scale(frontScaleX, frontScaleY); // Volumetric foreshortening scale sweep
    
    final upperFrontColorLight = Color.lerp(const Color(0xFF81C784), const Color(0xFFA5D6A7), upperFrontShade)!;
    final upperFrontColorDark = Color.lerp(const Color(0xFF2E7D32), const Color(0xFF1B5E20), (1.0 - upperFrontShade))!;
    final limbPaintFgFront = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [upperFrontColorLight, upperFrontColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, -22, 22, 22));

    final upperFrontFlipperPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(18, -16, 22, -22)
      ..quadraticBezierTo(12, -32, -4, -12)
      ..close();
    canvas.drawPath(upperFrontFlipperPath, limbPaintFgFront);
    canvas.restore();

    // 2. Upper Rear Leg
    canvas.save();
    canvas.translate(-16, -8);
    canvas.rotate(-flipperRow * 0.4 - 0.2);
    canvas.scale(rearScaleX, rearScaleY);
    
    final upperRearColorLight = Color.lerp(const Color(0xFF66BB6A), const Color(0xFF81C784), upperRearShade)!;
    final upperRearColorDark = Color.lerp(const Color(0xFF1B5E20), const Color(0xFF0C2E0C), (1.0 - upperRearShade))!;
    final limbPaintFgRear = Paint()
      ..isAntiAlias = true
      ..shader = LinearGradient(
        colors: [upperRearColorLight, upperRearColorDark],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(-15, -10, 15, 10));

    final upperRearLegPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-10, -12, -15, -10)
      ..quadraticBezierTo(-10, -2, 0, 0)
      ..close();
    canvas.drawPath(upperRearLegPath, limbPaintFgRear);
    canvas.restore();

    // E. Draw Carapace (Shell) with rich volumetric green gradients
    final shellPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF0D320D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 26));
    
    // Beautiful oval shell base
    final shellRect = Rect.fromCenter(center: Offset.zero, width: 50, height: 38);
    canvas.drawOval(shellRect, shellPaint);

    // Glossy linear specular refraction glint sweep (diagonal refraction light bar sweeping across dome)
    final double sweepPeriod = 8.0;
    final double sweepDuration = 1.6;
    final double sweepTime = timePhase % sweepPeriod;
    if (sweepTime < sweepDuration) {
      final double sweepProgress = sweepTime / sweepDuration; // 0.0 to 1.0
      final glintPaint = Paint()
        ..isAntiAlias = true
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.28),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0.3, 0.5, 0.7],
          begin: Alignment(-2.0 + sweepProgress * 4.0, -1.0),
          end: Alignment(-1.0 + sweepProgress * 4.0, 1.0),
        ).createShader(shellRect);
      canvas.drawOval(shellRect, glintPaint);
    }

    // F. Draw EMBOSSED 3D Scute Plates (Dual shadow/highlight beveling strokes)
    final double scuteWiggle = math.sin(timePhase * 3.0) * 0.15;
    
    final Path scutePath = Path();
    // Inner ring
    scutePath.addOval(Rect.fromCenter(center: Offset(scuteWiggle, 0), width: 34, height: 24));
    // Radial division lines
    scutePath.moveTo(-17 + scuteWiggle, 0); scutePath.lineTo(-25, 0);
    scutePath.moveTo(17 + scuteWiggle, 0); scutePath.lineTo(25, 0);
    scutePath.moveTo(scuteWiggle, -12); scutePath.lineTo(0, -19);
    scutePath.moveTo(scuteWiggle, 12); scutePath.lineTo(0, 19);
    scutePath.moveTo(-10 + scuteWiggle, -10); scutePath.lineTo(-17, -14);
    scutePath.moveTo(10 + scuteWiggle, -10); scutePath.lineTo(17, -14);
    scutePath.moveTo(-10 + scuteWiggle, 10); scutePath.lineTo(-17, 14);
    scutePath.moveTo(10 + scuteWiggle, 10); scutePath.lineTo(17, 14);

    // 1. Embossed Shadow Path (drawn offset slightly bottom-right)
    canvas.save();
    canvas.translate(0.8, 0.8);
    final scuteShadowPaint = Paint()
      ..color = const Color(0xFF041204).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;
    canvas.drawPath(scutePath, scuteShadowPaint);
    canvas.restore();

    // 2. Embossed Highlight Path (drawn offset slightly top-left)
    canvas.save();
    canvas.translate(-0.8, -0.8);
    final scuteHighlightPaint = Paint()
      ..color = const Color(0xFFE8F5E9).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;
    canvas.drawPath(scutePath, scuteHighlightPaint);
    canvas.restore();

    // G. Draw 3D Spherical Specular Parallax Gloss Highlight
    final double lookDx = (lookTarget.dx - 0.5) * 4.0;
    final double lookDy = (lookTarget.dy - 0.5) * 4.0;
    
    // Calculate light reflection position shifted in opposition to look direction to mimic glassy dome depth
    final Offset specularOffset = Offset(-5.0 - lookDx * 0.7, -4.0 - lookDy * 0.7);
    final highlightPaint = Paint()
      ..isAntiAlias = true
      ..shader = RadialGradient(
        colors: [Colors.white.withValues(alpha: 0.42), Colors.white.withValues(alpha: 0.0)],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: specularOffset, radius: 18));
    canvas.drawOval(Rect.fromCenter(center: specularOffset, width: 40, height: 30), highlightPaint);

    // H. Premium shell rim outer highlight
    final rimPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawOval(shellRect, rimPaint);

    // I. Draw Expressive Gaze-Tracking Eye & Mouth (matching neck lag inertia)
    canvas.save();
    canvas.translate(-tiltAngle * 3.0, -tiltAngle.abs() * 1.5);
    
    final eyeCenter = const Offset(29.0, -6.0);
    const double eyeRadius = 6.2;

    if (activeState == 'tickled') {
      // Draw happy squinting curved eyes ^ _ ^
      paint.shader = null;
      paint.color = const Color(0xFF0F3810);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.4;
      paint.strokeCap = StrokeCap.round;

      final eyePath = Path()
        ..moveTo(eyeCenter.dx - 4.5, eyeCenter.dy + 1.5)
        ..quadraticBezierTo(eyeCenter.dx, eyeCenter.dy - 3.5, eyeCenter.dx + 4.5, eyeCenter.dy + 1.5);
      canvas.drawPath(eyePath, paint);
    } else if (activeState == 'sleeping') {
      // Draw sleeping peaceful closed slit eyes - _ -
      paint.shader = null;
      paint.color = const Color(0xFF0F3810);
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 2.2;
      paint.strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(eyeCenter.dx - 4.0, eyeCenter.dy),
        Offset(eyeCenter.dx + 4.0, eyeCenter.dy),
        paint,
      );
    } else {
      // Normal dynamic pupil tracking eye
      // White sclera
      paint.shader = null;
      paint.color = Colors.white;
      paint.style = PaintingStyle.fill;
      canvas.drawCircle(eyeCenter, eyeRadius, paint);

      // Pupils looking at lookTarget
      final pupilOffset = Offset(
        facingLeft ? -lookDx * 0.8 : lookDx * 0.8,
        lookDy * 0.8,
      );

      // Pupil color based on mood
      if (statusMood == 'critical') {
        paint.color = Colors.redAccent.shade700;
      } else if (statusMood == 'warning') {
        paint.color = Colors.orange.shade800;
      } else {
        paint.color = const Color(0xFF263238);
      }
      canvas.drawCircle(eyeCenter + pupilOffset, eyeRadius * 0.58, paint);

      // Reflection Glare
      paint.color = Colors.white;
      canvas.drawCircle(eyeCenter + pupilOffset - const Offset(1.5, 1.5), eyeRadius * 0.22, paint);
    }

    // J. Draw Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF0F3810)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    if (activeState == 'eating') {
      // Chewing/Munching "O" mouth shape
      mouthPaint.style = PaintingStyle.fill;
      mouthPaint.color = const Color(0xFF0F3810);
      canvas.drawCircle(const Offset(33.0, 1.0), 3.0, mouthPaint);
    } else if (statusMood == 'critical') {
      // Worried flat wiggly line
      mouthPath.moveTo(30, 1);
      mouthPath.quadraticBezierTo(32, -1, 35, 2);
      canvas.drawPath(mouthPath, mouthPaint);
    } else if (statusMood == 'warning') {
      // Flat line mouth
      mouthPath.moveTo(30, 1);
      mouthPath.lineTo(34, 1);
      canvas.drawPath(mouthPath, mouthPaint);
    } else {
      // Happy standard smile!
      mouthPath.arcTo(
        Rect.fromLTWH(28, -2, 6, 6),
        0.1,
        math.pi * 0.95,
        false,
      );
      canvas.drawPath(mouthPath, mouthPaint);
    }
    
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PondyPainter oldDelegate) {
    return oldDelegate.pondyPosition != pondyPosition ||
        oldDelegate.facingLeft != facingLeft ||
        oldDelegate.activeState != activeState ||
        oldDelegate.statusMood != statusMood ||
        oldDelegate.pellets.length != pellets.length ||
        oldDelegate.bubbles.length != bubbles.length ||
        oldDelegate.happyEmojis.length != happyEmojis.length ||
        oldDelegate.lookTarget != lookTarget ||
        oldDelegate.timePhase != timePhase ||
        oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.swimRipples.length != swimRipples.length;
  }
}
