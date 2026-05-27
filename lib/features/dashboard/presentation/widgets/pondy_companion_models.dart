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

/// Representation of Pondy's evolution level, vibrancy, neglect, and achievements.
class PondyEvolutionState {
  final int level; // 1 (Standard), 2 (Hat), 3 (Crown)
  final bool isVibrant;
  final bool isNeglected;
  final String statusMood; // 'stable', 'warning', 'critical'
  final int streakDays;
  final bool hasFirstWeekStreak;
  final bool hasPerfectPhMonth;
  final bool hasZeroAlertsWeek;
  final bool hasAnyPond;

  const PondyEvolutionState({
    required this.level,
    required this.isVibrant,
    required this.isNeglected,
    required this.statusMood,
    required this.streakDays,
    required this.hasFirstWeekStreak,
    required this.hasPerfectPhMonth,
    required this.hasZeroAlertsWeek,
    required this.hasAnyPond,
  });

  const PondyEvolutionState.empty()
      : level = 1,
        isVibrant = false,
        isNeglected = false,
        statusMood = 'stable',
        streakDays = 0,
        hasFirstWeekStreak = false,
        hasPerfectPhMonth = false,
        hasZeroAlertsWeek = false,
        hasAnyPond = false;
}

