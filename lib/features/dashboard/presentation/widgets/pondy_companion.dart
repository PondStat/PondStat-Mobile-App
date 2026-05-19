import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Representation of a food pellet falling in the water.
class FeedPellet {
  Offset position;
  final double speed;
  final double size;

  FeedPellet({
    required this.position,
    required this.speed,
    required this.size,
  });
}

/// Representation of a rising air bubble.
class BubbleParticle {
  Offset position;
  final double speed;
  final double size;
  final double angleFrequency;
  final double angleAmplitude;
  double life = 1.0; // Fades out as it rises

  BubbleParticle({
    required this.position,
    required this.speed,
    required this.size,
    required this.angleFrequency,
    required this.angleAmplitude,
  });
}

/// Floating bubble heart emoji triggered on feeding.
class HappyEmoji {
  Offset position;
  final String emoji;
  double life = 1.0;

  HappyEmoji({required this.position, required this.emoji});
}

/// Representation of a trailing swim wake ripple.
class SwimRipple {
  final Offset position;
  final double initialRadius;
  double life = 1.0; // Fades out as it grows

  SwimRipple({
    required this.position,
    required this.initialRadius,
  });
}

class PondyCompanion extends StatefulWidget {
  final String statusMood; // 'stable', 'warning', 'critical'
  final Function(String message)? onEat;
  final bool isFullScreen;
  final bool isNightMode;
  final int cleanTrigger;
  final Offset? targetFoodPosition;

  const PondyCompanion({
    super.key,
    this.statusMood = 'stable',
    this.onEat,
    this.isFullScreen = false,
    this.isNightMode = false,
    this.cleanTrigger = 0,
    this.targetFoodPosition,
  });

  @override
  State<PondyCompanion> createState() => _PondyCompanionState();
}

class _PondyCompanionState extends State<PondyCompanion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickController;

  // Physics state
  Offset _pondyPosition = const Offset(60, 70);
  Offset _targetPosition = const Offset(60, 70);
  bool _facingLeft = false;
  final double _swimSpeed = 4.5;
  String _activeState = 'idle'; // 'idle', 'swimming', 'eating', 'sleeping', 'tickled'
  int _eatingTicks = 0;

  // Volumetric 3D physics lag & tilt
  Offset _lastPondyPosition = const Offset(60, 70);
  double _tiltAngle = 0.0;
  Offset _velocity = Offset.zero;

  // Premium interactive states
  int _idleTicks = 0;
  int _tickleTicks = 0;
  Offset _smoothedLookTarget = const Offset(0.5, 0.5);
  final List<SwimRipple> _swimRipples = [];

  // Wandering state and viewport dimensions
  double _width = 120.0;
  double _height = 140.0;
  Offset _wanderTarget = const Offset(60, 70);
  int _wanderCooldown = 0;

  final List<FeedPellet> _pellets = [];
  final List<BubbleParticle> _bubbles = [];
  final List<HappyEmoji> _happyEmojis = [];

  Offset _lookTarget = const Offset(0.5, 0.5); // Pupil look direction
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _lastPondyPosition = _pondyPosition;
    // Continuous physics/animation ticker running at 60 FPS
    _tickController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick)..repeat();
  }

  @override
  void dispose() {
    _tickController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PondyCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cleanTrigger != oldWidget.cleanTrigger && widget.cleanTrigger > 0) {
      _triggerCleanBubbles();
    }
  }

  void _triggerCleanBubbles() {
    setState(() {
      for (int i = 0; i < 40; i++) {
        _bubbles.add(BubbleParticle(
          position: Offset(_random.nextDouble() * _width, _height + 15),
          speed: 1.2 + _random.nextDouble() * 2.2,
          size: 4.0 + _random.nextDouble() * 7.0,
          angleFrequency: 3.0 + _random.nextDouble() * 4.0,
          angleAmplitude: 0.5 + _random.nextDouble() * 1.5,
        ));
      }
    });
  }

  void _onTick() {
    if (!mounted) return;

    setState(() {
      final double progress = _tickController.value;

      // 0. Update Swim Ripples (Fluid trail wakes)
      for (int i = _swimRipples.length - 1; i >= 0; i--) {
        final ripple = _swimRipples[i];
        ripple.life -= 0.02; // Fades over 50 ticks (approx 0.83 seconds)
        if (ripple.life <= 0) {
          _swimRipples.removeAt(i);
        }
      }

      // 1. Update Food Pellets (Gravity physics)
      for (int i = _pellets.length - 1; i >= 0; i--) {
        final pellet = _pellets[i];
        // Sink downwards
        pellet.position = Offset(pellet.position.dx, pellet.position.dy + pellet.speed);
        
        // Remove if off bottom boundary
        if (pellet.position.dy > _height) {
          _pellets.removeAt(i);
        }
      }

      // 2. Update Bubbles (Buoyancy and sinusoidal drift physics)
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final bubble = _bubbles[i];
        // Drift upwards
        final double drift = math.sin(progress * bubble.angleFrequency) * bubble.angleAmplitude;
        bubble.position = Offset(bubble.position.dx + drift, bubble.position.dy - bubble.speed);
        bubble.life -= 0.015;

        // Remove if faded or off screen
        if (bubble.position.dy < -10 || bubble.life <= 0) {
          _bubbles.removeAt(i);
        }
      }

      // 3. Update Emojis
      for (int i = _happyEmojis.length - 1; i >= 0; i--) {
        final emoji = _happyEmojis[i];
        emoji.position = Offset(emoji.position.dx, emoji.position.dy - 1.2);
        emoji.life -= 0.02;
        if (emoji.life <= 0) {
          _happyEmojis.removeAt(i);
        }
      }

      // 4. Companion Target Pursuit AI & Interactive States
      if (_tickleTicks > 0) {
        _tickleTicks--;
        _activeState = 'tickled';
        _idleTicks = 0; // Reset inactivity
      } else if (_eatingTicks > 0) {
        _eatingTicks--;
        if (_eatingTicks == 0) {
          _activeState = 'idle';
        }
      }

      if (_tickleTicks == 0 && _eatingTicks == 0) {
        // Find closest pellet if any
        if (_pellets.isNotEmpty) {
          _activeState = 'swimming';
          _idleTicks = 0; // Reset inactivity
          // Target the oldest pellet first (first in queue)
          final targetPellet = _pellets.first;
          _targetPosition = targetPellet.position;

          // Smooth swim interpolation towards target
          final dx = _targetPosition.dx - _pondyPosition.dx;
          final dy = _targetPosition.dy - _pondyPosition.dy;
          final distance = math.sqrt(dx * dx + dy * dy);

          if (distance > 6.0) {
            _facingLeft = dx < 0;
            final double ratio = _swimSpeed / distance;
            _pondyPosition = Offset(
              _pondyPosition.dx + dx * ratio.clamp(0.0, 1.0),
              _pondyPosition.dy + dy * ratio.clamp(0.0, 1.0),
            );

            // Update pupil tracking look target
            _lookTarget = Offset(
              _facingLeft ? 0.2 : 0.8,
              dy > 0 ? 0.8 : 0.2,
            );
          } else {
            // Reached the pellet! Munch it!
            _pellets.removeAt(0);
            _activeState = 'eating';
            _eatingTicks = 35; // Duration of eating facial/chewing expression (ticks)
            HapticFeedback.lightImpact();

            // Spawn happy bubble burst and heart emoji!
            _happyEmojis.add(HappyEmoji(
              position: Offset(_pondyPosition.dx, _pondyPosition.dy - 25),
              emoji: _random.nextBool() ? '❤️' : '🫧',
            ));

            // Trigger bubble burst
            for (int b = 0; b < 6; b++) {
              _bubbles.add(BubbleParticle(
                position: _pondyPosition,
                speed: 1.0 + _random.nextDouble() * 1.5,
                size: 3.0 + _random.nextDouble() * 5.0,
                angleFrequency: 8.0 + _random.nextDouble() * 6.0,
                angleAmplitude: 0.5 + _random.nextDouble() * 1.0,
              ));
            }

            if (widget.onEat != null) {
              final lines = [
                "Yum! Absolutely delicious!",
                "Munch munch! Thank you!",
                "Burp! High-quality nutrition!",
                "That hits the spot!",
                "Chomp! Best feed ever!",
              ];
              widget.onEat!(lines[_random.nextInt(lines.length)]);
            }
          }
        } else {
          // Idle wandering or Sleeping state
          if (widget.isFullScreen && widget.isNightMode) {
            _activeState = 'sleeping';
            _idleTicks++;
            
            // Blow lazy sleep Zzz emoji bubble
            if (_idleTicks % 120 == 0) {
              _happyEmojis.add(HappyEmoji(
                position: Offset(_pondyPosition.dx + 12, _pondyPosition.dy - 12),
                emoji: '💤',
              ));
            }

            // Sleep drifting slowly downwards in full screen
            final double homeDx = (_width / 2.0) - _pondyPosition.dx;
            final double homeDy = (_height - 65.0) - _pondyPosition.dy;
            _pondyPosition = Offset(
              _pondyPosition.dx + homeDx * 0.02,
              _pondyPosition.dy + homeDy * 0.02,
            );
            _lookTarget = const Offset(0.5, 0.6);
          } else if (widget.isFullScreen && widget.targetFoodPosition != null) {
            _activeState = 'swimming';
            _idleTicks = 0; // reset idle sleep ticks

            final dx = widget.targetFoodPosition!.dx - _pondyPosition.dx;
            final dy = widget.targetFoodPosition!.dy - _pondyPosition.dy;
            final distance = math.sqrt(dx * dx + dy * dy);

            // Hit test: did we arrive at the pellet?
            if (distance < 28.0) {
              _activeState = 'tickled'; // trigger excited chewing/wiggle face
              _happyEmojis.add(HappyEmoji(
                position: Offset(_pondyPosition.dx + 15, _pondyPosition.dy - 10),
                emoji: '✨',
              ));
              if (widget.onEat != null) {
                widget.onEat!("Nom Nom Nom!");
              }
              HapticFeedback.heavyImpact();
            }

            // Swim excited/faster towards active food pellet
            if (distance > 2.0) {
              _facingLeft = dx < 0;
              const double pursuitSpeed = 3.2; // faster speed for target chase
              final double ratio = pursuitSpeed / distance;
              _pondyPosition = Offset(
                _pondyPosition.dx + dx * ratio.clamp(0.0, 1.0),
                _pondyPosition.dy + dy * ratio.clamp(0.0, 1.0),
              );
              // Face the food coordinates
              _lookTarget = Offset(
                _facingLeft ? 0.2 : 0.8,
                dy > 0 ? 0.7 : 0.3,
              );
            }
          } else if (widget.isFullScreen) {

            // Check if we reached the target or cooldown expired
            final dx = _wanderTarget.dx - _pondyPosition.dx;
            final dy = _wanderTarget.dy - _pondyPosition.dy;
            final distance = math.sqrt(dx * dx + dy * dy);

            // Bounds constraints
            final double marginX = 40.0;
            final double marginY = 80.0;
            final double rangeX = (_width - marginX * 2).clamp(10.0, double.infinity);
            final double rangeY = (_height - marginY * 2).clamp(10.0, double.infinity);

            if (distance < 20.0 || _wanderCooldown <= 0) {
              // Pick a new random wandering target coordinate within constraints
              _wanderTarget = Offset(
                marginX + _random.nextDouble() * rangeX,
                marginY + _random.nextDouble() * rangeY,
              );
              _wanderCooldown = 180 + _random.nextInt(220); // ticks (3.0 to 6.6 seconds)
            } else {
              _wanderCooldown--;
            }

            // Swim smoothly towards wandering target (relaxed ambient speed)
            if (distance > 2.0) {
              _facingLeft = dx < 0;
              const double ambientSpeed = 1.0;
              final double ratio = ambientSpeed / distance;
              _pondyPosition = Offset(
                _pondyPosition.dx + dx * ratio.clamp(0.0, 1.0),
                _pondyPosition.dy + dy * ratio.clamp(0.0, 1.0),
              );
              _lookTarget = Offset(
                _facingLeft ? 0.3 : 0.7,
                dy > 0 ? 0.6 : 0.4,
              );
            }
          } else {
            // Dashboard mode sleep/idle logic
            _idleTicks++;
            if (_idleTicks > 900) { // 15 seconds of inactivity
              _activeState = 'sleeping';
              
              // Blow lazy sleep Zzz emoji bubble
              if (_idleTicks % 120 == 0) {
                _happyEmojis.add(HappyEmoji(
                  position: Offset(_pondyPosition.dx + 12, _pondyPosition.dy - 12),
                  emoji: '💤',
                ));
              }

              // Sleep drifting slowly downwards
              final double homeDx = (_width / 2.0) - _pondyPosition.dx;
              final double homeDy = (_height - 35.0) - _pondyPosition.dy;
              _pondyPosition = Offset(
                _pondyPosition.dx + homeDx * 0.02,
                _pondyPosition.dy + homeDy * 0.02,
              );
              _lookTarget = const Offset(0.5, 0.6);
            } else {
              _activeState = 'idle';

              // Gently drift back to center of aquarium
              final double homeDx = 60.0 - _pondyPosition.dx;
              final double homeDy = 70.0 - _pondyPosition.dy;
              _pondyPosition = Offset(
                _pondyPosition.dx + homeDx * 0.05,
                _pondyPosition.dy + homeDy * 0.05,
              );
              
              // Return gaze to normal
              _lookTarget = const Offset(0.5, 0.5);
            }
          }
        }
      }

      // Randomly spawn gentle rising bubbles in ambient full-screen mode
      if (widget.isFullScreen && _random.nextDouble() < 0.015 && _bubbles.length < 15) {
        _bubbles.add(BubbleParticle(
          position: Offset(_random.nextDouble() * _width, _height + 10),
          speed: 0.4 + _random.nextDouble() * 0.8,
          size: 2.0 + _random.nextDouble() * 3.5,
          angleFrequency: 4.0 + _random.nextDouble() * 4.0,
          angleAmplitude: 0.3 + _random.nextDouble() * 0.6,
        ));
      }

      // Volumetric 3D physics lag & tilt tracking
      _velocity = _pondyPosition - _lastPondyPosition;
      _lastPondyPosition = _pondyPosition;
      
      final double targetTilt = (_velocity.dx.abs() > 0.01 || _velocity.dy.abs() > 0.01)
          ? math.atan2(_velocity.dy, _velocity.dx.abs()) * 0.45
          : 0.0;
      _tiltAngle = _tiltAngle * 0.82 + targetTilt * 0.18;

      // Smooth eye/pupil tracking transition
      _smoothedLookTarget = Offset.lerp(_smoothedLookTarget, _lookTarget, 0.09)!;

      // Spawn fluid wake swim ripples behind tail
      if (_activeState == 'swimming' && _velocity.distance > 0.2 && _random.nextDouble() < 0.14 && _swimRipples.length < 10) {
        final Offset ripplePos = _pondyPosition - Offset(_facingLeft ? -18 : 18, 0);
        _swimRipples.add(SwimRipple(
          position: ripplePos,
          initialRadius: 8.0 + _random.nextDouble() * 4.0,
        ));
      }

      // Flipper stroke bubbles trail effect on downstrokes
      if (_activeState == 'swimming' && _random.nextDouble() < 0.15) {
        final double timePhase = DateTime.now().millisecondsSinceEpoch / 1000.0;
        final double cycleSpeed = _pellets.isNotEmpty ? 12.0 : 5.0;
        final double rowPhase = timePhase * cycleSpeed;
        
        if (math.cos(rowPhase) > 0.75) {
          final double bubbleX = _pondyPosition.dx + (_facingLeft ? 16 : -16);
          final double bubbleY = _pondyPosition.dy + (_random.nextBool() ? 12 : -12);
          
          _bubbles.add(BubbleParticle(
            position: Offset(bubbleX, bubbleY),
            speed: 0.3 + _random.nextDouble() * 0.5,
            size: 1.5 + _random.nextDouble() * 2.0,
            angleFrequency: 6.0 + _random.nextDouble() * 4.0,
            angleAmplitude: 0.2 + _random.nextDouble() * 0.3,
          ));
        }
      }
    });
  }

  void _handleTap(TapUpDetails details) {
    setState(() {
      _idleTicks = 0; // reset inactivity
      if (_activeState == 'sleeping') {
        _activeState = 'swimming';
        _happyEmojis.add(HappyEmoji(
          position: Offset(_pondyPosition.dx, _pondyPosition.dy - 20),
          emoji: '❗',
        ));
      }

      final tapPos = details.localPosition;
      final dx = tapPos.dx - _pondyPosition.dx;
      final dy = tapPos.dy - _pondyPosition.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < 38.0) {
        // Pet / tickle Pondy directly!
        _activeState = 'tickled';
        _tickleTicks = 60; // 1 second of intense joy wiggling!
        HapticFeedback.mediumImpact();

        _happyEmojis.add(HappyEmoji(
          position: Offset(_pondyPosition.dx, _pondyPosition.dy - 25),
          emoji: _random.nextBool() ? '✨' : '💖',
        ));

        // Spawning star-burst bubble ring
        for (int i = 0; i < 4; i++) {
          _bubbles.add(BubbleParticle(
            position: _pondyPosition,
            speed: 0.8 + _random.nextDouble() * 1.5,
            size: 2.0 + _random.nextDouble() * 3.0,
            angleFrequency: 5.0 + _random.nextDouble() * 4.0,
            angleAmplitude: 0.4 + _random.nextDouble() * 0.6,
          ));
        }
      } else {
        // Spawn standard food pellet at tap coordinates
        _pellets.add(FeedPellet(
          position: tapPos,
          speed: 1.2 + _random.nextDouble() * 0.8,
          size: 6.0 + _random.nextDouble() * 3.0,
        ));

        // Spawn bubble visual ripple
        for (int i = 0; i < 4; i++) {
          _bubbles.add(BubbleParticle(
            position: tapPos,
            speed: 1.0 + _random.nextDouble() * 2.0,
            size: 4.0 + _random.nextDouble() * 5.0,
            angleFrequency: 6.0 + _random.nextDouble() * 4.0,
            angleAmplitude: 0.8 + _random.nextDouble() * 1.2,
          ));
        }
      }
    });
  }

  void _handleDrag(DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = box.globalToLocal(details.globalPosition);
    setState(() {
      _idleTicks = 0; // reset inactivity
      if (_activeState == 'sleeping') {
        _activeState = 'swimming';
        _happyEmojis.add(HappyEmoji(
          position: Offset(_pondyPosition.dx, _pondyPosition.dy - 20),
          emoji: '👀',
        ));
      }

      final dx = localPos.dx - _pondyPosition.dx;
      final dy = localPos.dy - _pondyPosition.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      if (distance < 38.0) {
        // Dragging directly over Pondy keeps tickling/petting him!
        if (_tickleTicks < 15) {
          _activeState = 'tickled';
          _tickleTicks = 45;
          HapticFeedback.selectionClick();
          
          if (_random.nextDouble() < 0.15) {
            _happyEmojis.add(HappyEmoji(
              position: Offset(_pondyPosition.dx, _pondyPosition.dy - 25),
              emoji: '💖',
            ));
          }
        }
      }

      _lookTarget = Offset(
        (localPos.dx / box.size.width).clamp(0.0, 1.0),
        (localPos.dy / box.size.height).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        _height = constraints.maxHeight;

        final Widget childWidget = Container(
          color: Colors.transparent, // Capture taps across full canvas
          child: CustomPaint(
            painter: PondyPainter(
              pondyPosition: _pondyPosition,
              facingLeft: _facingLeft,
              activeState: _activeState,
              statusMood: widget.statusMood,
              pellets: _pellets,
              bubbles: _bubbles,
              happyEmojis: _happyEmojis,
              lookTarget: _smoothedLookTarget,
              timePhase: DateTime.now().millisecondsSinceEpoch / 1000.0,
              tiltAngle: _tiltAngle,
              swimRipples: _swimRipples,
            ),
            child: const SizedBox.expand(),
          ),
        );

        if (!widget.isFullScreen) {
          return childWidget;
        }

        return GestureDetector(
          onTapUp: _handleTap,
          onPanUpdate: _handleDrag,
          onPanEnd: (_) {
            setState(() {
              _lookTarget = const Offset(0.5, 0.5);
              _idleTicks = 0;
            });
          },
          child: childWidget,
        );
      },
    );
  }
}

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
