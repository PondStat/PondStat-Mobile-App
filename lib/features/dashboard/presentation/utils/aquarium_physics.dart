import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../widgets/aquarium_models.dart';

class AquariumPhysics {
  /// Updates positions and statuses of all aquarium entities using movement physics.
  /// Returns the updated [hapticCooldown].
  static double updateEcosystem({
    required List<NeonFish> fishList,
    required List<FoodPellet> foodPellets,
    required List<AlgaeParticle> algaeParticles,
    required List<PlanktonParticle> planktonList,
    required List<NeonJellyfish> jellyfishList,
    required List<VibeBubble> vibeBubbles,
    required double timePhase,
    required double width,
    required double height,
    required bool isNightMode,
    required bool vibeMode,
    required double hapticCooldown,
    required math.Random random,
  }) {
    double updatedHapticCooldown = hapticCooldown;

    // 1. Neon Schooling Fish Physics
    double avgX = 0;
    double avgY = 0;
    if (fishList.isNotEmpty) {
      for (final fish in fishList) {
        avgX += fish.position.dx;
        avgY += fish.position.dy;
      }
      avgX /= fishList.length;
      avgY /= fishList.length;
    }

    for (final fish in fishList) {
      final double dx = avgX - fish.position.dx;
      final double dy = avgY - fish.position.dy;
      final double distToCenter = math.sqrt(dx * dx + dy * dy);
      if (distToCenter > 15.0) {
        final double targetAngle = math.atan2(dy, dx);
        fish.angle = fish.angle * 0.96 + targetAngle * 0.04;
      }
      fish.angle += (random.nextDouble() - 0.5) * 0.14;
      fish.position += Offset(
        math.cos(fish.angle) * fish.speed,
        math.sin(fish.angle) * fish.speed,
      );

      final double margin = 40.0;
      if (fish.position.dx < -margin) fish.position = Offset(width + margin, fish.position.dy);
      if (fish.position.dx > width + margin) fish.position = Offset(-margin, fish.position.dy);
      if (fish.position.dy < 60.0) fish.position = Offset(fish.position.dx, height - 120.0);
      if (fish.position.dy > height - 100.0) fish.position = Offset(fish.position.dx, 100.0);
    }

    // 2. Food Pellets Sinking & Settling Gravity Physics
    for (int i = foodPellets.length - 1; i >= 0; i--) {
      final pellet = foodPellets[i];
      if (pellet.settled) {
        pellet.settleTicks++;
        pellet.opacity = (1.0 - (pellet.settleTicks / 240.0)).clamp(0.0, 1.0);
        if (pellet.settleTicks > 240) {
          foodPellets.removeAt(i);
        }
      } else {
        // Sinks slowly with gentle diagonal sinus drift
        final double drift = math.sin(timePhase * 3.5 + pellet.driftPhase) * 0.35;
        pellet.position += Offset(drift, pellet.speedY);

        // Sand dune collision check (seabed settled bounds)
        if (pellet.position.dy >= height - 32) {
          pellet.position = Offset(pellet.position.dx, height - 32);
          pellet.settled = true;
        }
      }
    }

    // 3. Floaty Algae Particles
    for (final algae in algaeParticles) {
      algae.position += Offset(algae.speedX, algae.speedY);
      algae.angle += 0.005;
      if (algae.position.dx < -20) algae.position = Offset(width + 20, algae.position.dy);
      if (algae.position.dx > width + 20) algae.position = Offset(-20, algae.position.dy);
      if (algae.position.dy < 40) algae.position = Offset(algae.position.dx, height - 80);
      if (algae.position.dy > height - 60) algae.position = Offset(algae.position.dx, 60);
    }

    // 4. Translucent Rising Plankton
    for (final plankton in planktonList) {
      final double waveDrift = math.sin(timePhase * 2.0 + plankton.phaseOffset) * 0.12;
      plankton.position = Offset(
        plankton.position.dx + waveDrift,
        plankton.position.dy - plankton.speedY,
      );
      if (plankton.position.dy < 40) {
        plankton.position = Offset(random.nextDouble() * width, height - 40);
      }
    }

    // 5. Bioluminescent Neon Jellyfish Pulsating Physics
    if (isNightMode) {
      for (final jelly in jellyfishList) {
        // Bell contraction drives movement bursts
        final double contraction = 1.0 + 0.16 * math.sin(timePhase * 2.6 + jelly.phaseOffset);
        final double effectiveSpeed = contraction < 0.95 ? jelly.speed * 2.0 : jelly.speed * 0.35;

        // Propels upward and drifts slightly left/right
        jelly.position = Offset(
          jelly.position.dx + math.sin(timePhase * 0.8 + jelly.phaseOffset) * 0.2,
          jelly.position.dy - effectiveSpeed,
        );

        if (jelly.position.dy < -jelly.size * 2) {
          jelly.position = Offset(random.nextDouble() * width, height + jelly.size * 2);
        }
      }
    }

    // 6. Vibe Mode Bubbles Generator & Pop Haptics
    if (vibeMode) {
      // Spawn bubble streams continuously
      if (random.nextDouble() < 0.08) {
        vibeBubbles.add(VibeBubble(
          position: Offset(random.nextDouble() * width, height + 10),
          speedY: 1.5 + random.nextDouble() * 2.0,
          size: 3.0 + random.nextDouble() * 5.0,
          phaseOffset: random.nextDouble() * 50.0,
        ));
      }

      // Physics loop for vibe bubbles
      updatedHapticCooldown -= 0.016;
      for (int i = vibeBubbles.length - 1; i >= 0; i--) {
        final bubble = vibeBubbles[i];
        bubble.position = Offset(
          bubble.position.dx + math.sin(timePhase * 4.0 + bubble.phaseOffset) * 0.45,
          bubble.position.dy - bubble.speedY,
        );

        // Popping haptics at surface check
        if (bubble.position.dy < 80.0) {
          vibeBubbles.removeAt(i);
          if (updatedHapticCooldown <= 0.0) {
            HapticFeedback.selectionClick();
            updatedHapticCooldown = 0.28; // avoid excessive haptic floods
          }
        }
      }
    } else {
      vibeBubbles.clear();
    }

    return updatedHapticCooldown;
  }
}
