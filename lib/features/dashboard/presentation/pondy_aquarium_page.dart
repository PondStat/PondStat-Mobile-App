import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'widgets/pondy_companion.dart';
import 'widgets/aquarium_painters.dart';

class PondyAquariumPage extends StatefulWidget {
  final String statusMood;

  const PondyAquariumPage({
    super.key,
    this.statusMood = 'stable',
  });

  @override
  State<PondyAquariumPage> createState() => _PondyAquariumPageState();
}

class _PondyAquariumPageState extends State<PondyAquariumPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  double _timePhase = 0.0;
  bool _isNightMode = false;
  int _cleanTrigger = 0;

  // Visual Equalizer Vibe Mode Toggle
  bool _vibeMode = false;
  double _hapticCooldown = 0.0;
  late final AudioPlayer _audioPlayer;
  int _audioTransitionToken = 0;

  // Ecosystem Particles and Organisms
  final List<NeonFish> _fishList = [];
  final List<FoodPellet> _foodPellets = [];
  final List<AlgaeParticle> _algaeParticles = [];
  final List<PlanktonParticle> _planktonList = [];
  final List<NeonJellyfish> _jellyfishList = [];
  final List<VibeBubble> _vibeBubbles = [];

  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (!mounted) return;
        setState(() {
          _timePhase += 0.016; // approx 60 FPS
          _updateEcosystemPhysics();
        });
      })..repeat();

    // 1. Spawn 12 background neon tetras
    for (int i = 0; i < 12; i++) {
      _fishList.add(NeonFish(
        position: Offset(
          100 + _random.nextDouble() * 200,
          150 + _random.nextDouble() * 400,
        ),
        speed: 1.0 + _random.nextDouble() * 1.5,
        angle: _random.nextDouble() * math.pi * 2,
        phaseOffset: _random.nextDouble() * 20.0,
        color: i % 2 == 0 ? const Color(0xFF00E5FF) : const Color(0xFFFF1744),
      ));
    }

    // 2. Spawn 20 translucent plankton specs
    for (int i = 0; i < 20; i++) {
      _planktonList.add(PlanktonParticle(
        position: Offset(
          _random.nextDouble() * 400.0,
          _random.nextDouble() * 700.0,
        ),
        speedY: 0.3 + _random.nextDouble() * 0.5,
        size: 1.5 + _random.nextDouble() * 2.0,
        phaseOffset: _random.nextDouble() * 100.0,
      ));
    }

    // 3. Spawn warning/critical algae particles depending on water parameter state
    _spawnAlgaeForMood();

    // 4. Spawn 3 background bioluminescent jellyfish
    for (int i = 0; i < 3; i++) {
      _jellyfishList.add(NeonJellyfish(
        position: Offset(
          50.0 + _random.nextDouble() * 300.0,
          300.0 + _random.nextDouble() * 300.0,
        ),
        speed: 0.4 + _random.nextDouble() * 0.4,
        phaseOffset: _random.nextDouble() * 50.0,
        color: i % 2 == 0 ? const Color(0xFFD500F9) : const Color(0xFF2979FF), // purple or bright blue
        size: 16.0 + _random.nextDouble() * 6.0,
      ));
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _toggleVibeAudio(bool enable) async {
    final token = ++_audioTransitionToken;
    try {
      if (enable) {
        await _audioPlayer.setVolume(0.0);
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(UrlSource('https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3'));
        
        // Slowly fade in volume over 500ms (20 steps of 25ms)
        for (int i = 1; i <= 20; i++) {
          await Future.delayed(const Duration(milliseconds: 25));
          if (token != _audioTransitionToken || !mounted) return;
          await _audioPlayer.setVolume(i / 20.0);
        }
      } else {
        // Slowly fade out volume over 500ms (20 steps of 25ms)
        for (int i = 20; i >= 0; i--) {
          await Future.delayed(const Duration(milliseconds: 25));
          if (token != _audioTransitionToken || !mounted) return;
          await _audioPlayer.setVolume(i / 20.0);
        }
        await _audioPlayer.stop();
      }
    } catch (e) {
      debugPrint("Vibe Mode Audio Error: $e");
    }
  }

  void _spawnAlgaeForMood() {
    _algaeParticles.clear();
    final mood = widget.statusMood;
    final int count = mood == 'critical' ? 18 : (mood == 'warning' ? 8 : 0);
    for (int i = 0; i < count; i++) {
      _algaeParticles.add(AlgaeParticle(
        position: Offset(
          _random.nextDouble() * 380.0,
          100.0 + _random.nextDouble() * 500.0,
        ),
        speedX: (_random.nextDouble() - 0.5) * 0.6,
        speedY: (_random.nextDouble() - 0.5) * 0.4,
        angle: _random.nextDouble() * math.pi,
        size: 3.0 + _random.nextDouble() * 3.5,
      ));
    }
  }

  void _updateEcosystemPhysics() {
    final double width = MediaQuery.of(context).size.width.clamp(200.0, 1000.0);
    final double height = MediaQuery.of(context).size.height.clamp(300.0, 2000.0);

    // 1. Neon Schooling Fish Physics
    double avgX = 0;
    double avgY = 0;
    if (_fishList.isNotEmpty) {
      for (final fish in _fishList) {
        avgX += fish.position.dx;
        avgY += fish.position.dy;
      }
      avgX /= _fishList.length;
      avgY /= _fishList.length;
    }

    for (final fish in _fishList) {
      final double dx = avgX - fish.position.dx;
      final double dy = avgY - fish.position.dy;
      final double distToCenter = math.sqrt(dx * dx + dy * dy);
      if (distToCenter > 15.0) {
        final double targetAngle = math.atan2(dy, dx);
        fish.angle = fish.angle * 0.96 + targetAngle * 0.04;
      }
      fish.angle += (_random.nextDouble() - 0.5) * 0.14;
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
    for (int i = _foodPellets.length - 1; i >= 0; i--) {
      final pellet = _foodPellets[i];
      if (pellet.settled) {
        pellet.settleTicks++;
        pellet.opacity = (1.0 - (pellet.settleTicks / 240.0)).clamp(0.0, 1.0);
        if (pellet.settleTicks > 240) {
          _foodPellets.removeAt(i);
        }
      } else {
        // Sinks slowly with gentle diagonal sinus drift
        final double drift = math.sin(_timePhase * 3.5 + pellet.driftPhase) * 0.35;
        pellet.position += Offset(drift, pellet.speedY);

        // Sand dune collision check (seabed settled bounds)
        if (pellet.position.dy >= height - 32) {
          pellet.position = Offset(pellet.position.dx, height - 32);
          pellet.settled = true;
        }
      }
    }

    // 3. Floaty Algae Particles
    for (final algae in _algaeParticles) {
      algae.position += Offset(algae.speedX, algae.speedY);
      algae.angle += 0.005;
      if (algae.position.dx < -20) algae.position = Offset(width + 20, algae.position.dy);
      if (algae.position.dx > width + 20) algae.position = Offset(-20, algae.position.dy);
      if (algae.position.dy < 40) algae.position = Offset(algae.position.dx, height - 80);
      if (algae.position.dy > height - 60) algae.position = Offset(algae.position.dx, 60);
    }

    // 4. Translucent Rising Plankton
    for (final plankton in _planktonList) {
      final double waveDrift = math.sin(_timePhase * 2.0 + plankton.phaseOffset) * 0.12;
      plankton.position = Offset(
        plankton.position.dx + waveDrift,
        plankton.position.dy - plankton.speedY,
      );
      if (plankton.position.dy < 40) {
        plankton.position = Offset(_random.nextDouble() * width, height - 40);
      }
    }

    // 5. Bioluminescent Neon Jellyfish Pulsating Physics
    if (_isNightMode) {
      for (final jelly in _jellyfishList) {
        // Bell contraction drives movement bursts
        final double contraction = 1.0 + 0.16 * math.sin(_timePhase * 2.6 + jelly.phaseOffset);
        final double effectiveSpeed = contraction < 0.95 ? jelly.speed * 2.0 : jelly.speed * 0.35;

        // Propels upward and drifts slightly left/right
        jelly.position = Offset(
          jelly.position.dx + math.sin(_timePhase * 0.8 + jelly.phaseOffset) * 0.2,
          jelly.position.dy - effectiveSpeed,
        );

        if (jelly.position.dy < -jelly.size * 2) {
          jelly.position = Offset(_random.nextDouble() * width, height + jelly.size * 2);
        }
      }
    }

    // 6. Vibe Mode Bubbles Generator & Pop Haptics
    if (_vibeMode) {
      // Spawn bubble streams continuously
      if (_random.nextDouble() < 0.08) {
        _vibeBubbles.add(VibeBubble(
          position: Offset(_random.nextDouble() * width, height + 10),
          speedY: 1.5 + _random.nextDouble() * 2.0,
          size: 3.0 + _random.nextDouble() * 5.0,
          phaseOffset: _random.nextDouble() * 50.0,
        ));
      }

      // Physics loop for vibe bubbles
      _hapticCooldown -= 0.016;
      for (int i = _vibeBubbles.length - 1; i >= 0; i--) {
        final bubble = _vibeBubbles[i];
        bubble.position = Offset(
          bubble.position.dx + math.sin(_timePhase * 4.0 + bubble.phaseOffset) * 0.45,
          bubble.position.dy - bubble.speedY,
        );

        // Popping haptics at surface check
        if (bubble.position.dy < 80.0) {
          _vibeBubbles.removeAt(i);
          if (_hapticCooldown <= 0.0) {
            HapticFeedback.selectionClick();
            _hapticCooldown = 0.28; // avoid excessive haptic floods
          }
        }
      }
    } else {
      _vibeBubbles.clear();
    }
  }

  void _spawnFoodPellet(Offset tapPos) {
    HapticFeedback.lightImpact();
    setState(() {
      _foodPellets.add(FoodPellet(
        position: Offset(tapPos.dx, 100), // Drop from surface level
        speedY: 1.1 + _random.nextDouble() * 0.6,
        driftPhase: _random.nextDouble() * 12.0,
        size: 5.5 + _random.nextDouble() * 2.5,
      ));
    });
  }

  // Find target coordinates of the closest sinking food pellet for Pondy Companion target gaze
  Offset? _getClosestFood() {
    final activePellets = _foodPellets.where((p) => !p.settled).toList();
    if (activePellets.isEmpty) return null;
    return activePellets.first.position; // pursue oldest active pellet
  }

  @override
  Widget build(BuildContext context) {
    final double height = MediaQuery.of(context).size.height;

    // Water gradients changing dynamically to status mood parameter health conditions!
    final String mood = widget.statusMood;
    final List<Color> backgroundColors;
    if (mood == 'critical') {
      backgroundColors = _isNightMode
          ? [
              const Color(0xFF010A10), // Midnight critical
              const Color(0xFF03121C),
              const Color(0xFF061A26),
            ]
          : [
              const Color(0xFF142724), // Gloomy Critical Mud-Green
              const Color(0xFF203B31),
              const Color(0xFF182823),
            ];
    } else if (mood == 'warning') {
      backgroundColors = _isNightMode
          ? [
              const Color(0xFF020E15), // Midnight warning
              const Color(0xFF041825),
              const Color(0xFF08273A),
            ]
          : [
              const Color(0xFF0E3032), // Yellowish Teal warning
              const Color(0xFF1B4944),
              const Color(0xFF123430),
            ];
    } else {
      backgroundColors = _isNightMode
          ? [
              const Color(0xFF020B14), // Pristine stable night
              const Color(0xFF041426),
              const Color(0xFF08223B),
            ]
          : [
              const Color(0xFF003D45), // Pristine stable day
              const Color(0xFF005C66),
              const Color(0xFF00838F),
            ];
    }

    return Scaffold(
      backgroundColor: backgroundColors.first,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final double tapY = details.globalPosition.dy;
          if (tapY < height - 110 && tapY > 100) {
            _spawnFoodPellet(details.globalPosition);
          }
        },
        child: Stack(
          children: [
            // 1. Dynamic Water Gradient Layer
            AnimatedContainer(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: backgroundColors,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const SizedBox.expand(),
            ),

            // 2. Wave Refracting God Rays
            Positioned.fill(
              child: CustomPaint(
                painter: GodRaysPainter(
                  timePhase: _timePhase,
                  isNightMode: _isNightMode,
                  statusMood: mood,
                ),
              ),
            ),

            // 3. Schooling Neon Tetras
            Positioned.fill(
              child: CustomPaint(
                painter: SchoolFishPainter(
                  fishList: _fishList,
                  timePhase: _timePhase,
                ),
              ),
            ),

            // 4. Bioluminescent Glowing Jellyfish forest in Night Mode
            if (_isNightMode)
              Positioned.fill(
                child: CustomPaint(
                  painter: JellyfishPainter(
                    jellyfishList: _jellyfishList,
                    timePhase: _timePhase,
                  ),
                ),
              ),

            // 5. Swaying Seaweed Stalks (Multilayer depth parallax kelp)
            Positioned.fill(
              child: CustomPaint(
                painter: SeaweedPainter(
                  timePhase: _timePhase,
                  isNightMode: _isNightMode,
                  statusMood: mood,
                ),
              ),
            ),

            // 6. Plankton, Algae, Feed Pellets, and Vibe Mode Bubbles Layer
            Positioned.fill(
              child: CustomPaint(
                painter: EcosystemParticlesPainter(
                  foodPellets: _foodPellets,
                  algaeParticles: _algaeParticles,
                  planktonList: _planktonList,
                  vibeBubbles: _vibeBubbles,
                  timePhase: _timePhase,
                ),
              ),
            ),

            // 7. Pondy Mascot Active Companion with Target Food Coordination
            Positioned.fill(
              child: PondyCompanion(
                statusMood: mood,
                isFullScreen: true,
                isNightMode: _isNightMode,
                cleanTrigger: _cleanTrigger,
                targetFoodPosition: _getClosestFood(),
                onEat: (msg) {
                  // Pellet eaten hit! Remove pellet from list
                  if (_foodPellets.isNotEmpty) {
                    setState(() {
                      _foodPellets.removeAt(0); // eat oldest pellet
                    });
                  }
                  HapticFeedback.lightImpact();
                },
              ),
            ),

            // 8. Sleek Glassmorphic Return Button (Top-Left)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: _isNightMode ? 0.0 : 0.15),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 9. Status Mood Dashboard Indicator & Vibe Equalizer (Top-Right)
            Positioned(
              top: MediaQuery.of(context).padding.top + 24,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_vibeMode) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (idx) {
                          final double waveH = 4.0 + 16.0 * (0.4 + 0.6 * math.sin(_timePhase * 11.0 + idx * 1.3));
                          return Container(
                            width: 3.0,
                            height: waveH,
                            margin: const EdgeInsets.symmetric(horizontal: 1.8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E5FF),
                              borderRadius: BorderRadius.circular(2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      _isNightMode ? Icons.nights_stay : Icons.wb_sunny_rounded,
                      color: _isNightMode ? const Color(0xFF90CAF9) : const Color(0xFFFFD54F),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isNightMode ? "Night" : "Day",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 10. Elegant Glassmorphic Interactive Control Bar (Bottom Drawer)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        // Dynamic Vibe Mode Toggle Simulator
                        _buildControlItem(
                          icon: _vibeMode ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          label: "Vibe Mode",
                          glowColor: _vibeMode ? const Color(0xFF00E5FF) : Colors.grey,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _vibeMode = !_vibeMode;
                              _toggleVibeAudio(_vibeMode);
                            });
                          },
                        ),

                        // Feed Button Hint Action
                        _buildControlItem(
                          icon: Icons.restaurant_menu_rounded,
                          label: "Feed Pondy",
                          glowColor: const Color(0xFF8D6E63),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Tap anywhere in the water area to drop sinking food pellets! 🍲"),
                                duration: Duration(milliseconds: 1800),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),

                        // Clean Tank Button
                        _buildControlItem(
                          icon: Icons.bubble_chart_rounded,
                          label: "Clean Tank",
                          glowColor: const Color(0xFF00E5FF),
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            setState(() {
                              _cleanTrigger++;
                              // Cleaning also purges floating critical algae dust
                              _spawnAlgaeForMood();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Releasing deep-cleaning bubble waves! 🫧✨"),
                                duration: Duration(milliseconds: 1500),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),

                        // Day/Night Mode Switch
                        _buildControlItem(
                          icon: _isNightMode ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded,
                          label: _isNightMode ? "Switch Day" : "Switch Night",
                          glowColor: _isNightMode ? const Color(0xFF3F51B5) : const Color(0xFFFFEB3B),
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _isNightMode = !_isNightMode;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlItem({
    required IconData icon,
    required String label,
    required Color glowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
