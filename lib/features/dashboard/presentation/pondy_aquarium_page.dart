import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:pondstat/features/dashboard/data/pondy_evolution_provider.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pondy_companion_models.dart';
import 'widgets/pondy_companion.dart';
import 'widgets/aquarium_painters.dart';
import 'widgets/aquarium_models.dart';
import 'utils/aquarium_physics.dart';

class PondyAquariumPage extends ConsumerStatefulWidget {
  final String statusMood;

  const PondyAquariumPage({
    super.key,
    this.statusMood = 'stable',
  });

  @override
  ConsumerState<PondyAquariumPage> createState() => _PondyAquariumPageState();
}

class _PondyAquariumPageState extends ConsumerState<PondyAquariumPage>
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
  bool _isDisposed = false;

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
    _isDisposed = true;
    try {
      _audioPlayer.stop();
      _audioPlayer.dispose();
    } catch (_) {}
    _ticker.dispose();
    super.dispose();
  }

  Future<void> _toggleVibeAudio(bool enable) async {
    final token = ++_audioTransitionToken;
    try {
      if (_isDisposed || !mounted) return;
      if (enable) {
        await _audioPlayer.setVolume(0.0);
        if (_isDisposed || !mounted) return;
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        if (_isDisposed || !mounted) return;
        await _audioPlayer.play(UrlSource('https://www.soundjay.com/nature/sounds/ocean-wave-1.mp3'));
        
        // Slowly fade in volume over 500ms (20 steps of 25ms)
        for (int i = 1; i <= 20; i++) {
          await Future.delayed(const Duration(milliseconds: 25));
          if (token != _audioTransitionToken || _isDisposed || !mounted) return;
          await _audioPlayer.setVolume(i / 20.0);
        }
      } else {
        // Slowly fade out volume over 500ms (20 steps of 25ms)
        for (int i = 20; i >= 0; i--) {
          await Future.delayed(const Duration(milliseconds: 25));
          if (token != _audioTransitionToken || _isDisposed || !mounted) return;
          await _audioPlayer.setVolume(i / 20.0);
        }
        if (_isDisposed || !mounted) return;
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

    _hapticCooldown = AquariumPhysics.updateEcosystem(
      fishList: _fishList,
      foodPellets: _foodPellets,
      algaeParticles: _algaeParticles,
      planktonList: _planktonList,
      jellyfishList: _jellyfishList,
      vibeBubbles: _vibeBubbles,
      timePhase: _timePhase,
      width: width,
      height: height,
      isNightMode: _isNightMode,
      vibeMode: _vibeMode,
      hapticCooldown: _hapticCooldown,
      random: _random,
    );
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
    final evolutionAsync = ref.watch(pondyEvolutionProvider);
    final evolution = evolutionAsync.value ?? const PondyEvolutionState.empty();
    final String mood = widget.statusMood == 'stable' ? evolution.statusMood : widget.statusMood;
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

                        // Achievements Button
                        _buildControlItem(
                          icon: Icons.emoji_events_rounded,
                          label: "Achievements",
                          glowColor: Colors.amber,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            _showAchievementsDialog(context, ref);
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

  void _showAchievementsDialog(BuildContext context, WidgetRef ref) {
    final evolution = ref.read(pondyEvolutionProvider).value ?? const PondyEvolutionState.empty();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark ? Colors.white12 : colorScheme.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.amber,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Achievements",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32, thickness: 1),

                    // Pondy's Current Level Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: evolution.level == 3
                              ? [Colors.amber.shade700.withValues(alpha: 0.25), Colors.amber.shade900.withValues(alpha: 0.1)]
                              : evolution.level == 2
                                  ? [colorScheme.primary.withValues(alpha: 0.2), colorScheme.primary.withValues(alpha: 0.05)]
                                  : [colorScheme.surfaceContainerHighest, colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: evolution.level == 3
                              ? Colors.amber.withValues(alpha: 0.4)
                              : evolution.level == 2
                                  ? colorScheme.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : Colors.white60,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              evolution.level == 3
                                  ? "👑"
                                  : evolution.level == 2
                                      ? "🤠"
                                      : "🐢",
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pondy Evolution: Level ${evolution.level}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: evolution.level == 3
                                        ? Colors.amber.shade800
                                        : evolution.level == 2
                                            ? colorScheme.primary
                                            : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  evolution.level == 3
                                      ? "Monarch: Pondy is wearing the Golden Crown! Keep up the brilliant monitoring streak."
                                      : evolution.level == 2
                                          ? "Cowboy Scout: Pondy wears a cool Cowboy Hat. Active monitoring is going great!"
                                          : "Hatchling: Standard form. Monitored less than 3 days in the past week.",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Streak Activity Progress
                    Text(
                      "Monitoring Activity",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Active Days (Past 30d)",
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                "${evolution.streakDays} / 30 days",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (evolution.streakDays / 30).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Badges Section
                    Text(
                      "Badges & Streaks",
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    _buildBadgeTile(
                      context,
                      title: "First Week Streak",
                      description: "Record measurements on 7 distinct days in the last 30 days.",
                      icon: Icons.calendar_month_rounded,
                      unlocked: evolution.hasFirstWeekStreak,
                      badgeColor: Colors.purple,
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeTile(
                      context,
                      title: "Perfect pH Month",
                      description: "Record pH values and keep them within safe levels with zero pH alerts for 30 days.",
                      icon: Icons.opacity_rounded,
                      unlocked: evolution.hasPerfectPhMonth,
                      badgeColor: Colors.blue,
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeTile(
                      context,
                      title: "Zero Alerts Week",
                      description: "No warnings or critical alerts triggered across all ponds in the past 7 days.",
                      icon: Icons.verified_user_rounded,
                      unlocked: evolution.hasZeroAlertsWeek,
                      badgeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadgeTile(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required bool unlocked,
    required Color badgeColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.01),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked
              ? badgeColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unlocked
                  ? badgeColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: unlocked ? badgeColor : Colors.grey.shade500,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: unlocked ? null : Colors.grey.shade500,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            unlocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                            size: 10,
                            color: unlocked ? Colors.green : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            unlocked ? "Unlocked" : "Locked",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: unlocked ? Colors.green : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
