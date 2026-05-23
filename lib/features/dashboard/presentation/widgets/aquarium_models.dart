import 'package:flutter/material.dart';

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
