import 'package:flutter/material.dart';

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
