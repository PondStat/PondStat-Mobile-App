import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pondy_companion_models.dart';
import 'pondy_painter.dart';

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
