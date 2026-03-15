import 'dart:async';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatefulWidget {
  final bool isExiting;

  const LoadingOverlay({
    super.key,
    this.isExiting = false,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  Timer? _statusTimer;
  int _messageIndex = 0;

  final List<String> _loadingMessages = [
    'Preparing the pond...',
    'Waking up the fish...',
    'Fetching water quality data...',
    'Calibrating sensors...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  Widget _buildRipple(double animationValue, double baseSize) {
    final double size = baseSize + (animationValue * (baseSize * 0.5));
    final double opacity = 1.0 - animationValue;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity * 0.15),
        border: Border.all(
          color: Colors.white.withOpacity(opacity * 0.5),
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF0077C2);
    final Size screenSize = MediaQuery.sizeOf(context);

    final double safeAnimationSize = (screenSize.height * 0.35).clamp(200.0, 350.0);

    return AnimatedOpacity(
      opacity: widget.isExiting ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Semantics(
        label: 'Loading PondStat app data, please wait.',
        child: Scaffold(
          backgroundColor: primaryColor,
          body: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: safeAnimationSize,
                      child: AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          final double pulseScale = 1.0 + (0.05 * _rippleController.value);

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              _buildRipple(
                                _rippleController.value,
                                safeAnimationSize * 0.5,
                              ),
                              _buildRipple(
                                (_rippleController.value + 0.5) % 1.0,
                                safeAnimationSize * 0.5,
                              ),
                              Transform.scale(
                                scale: pulseScale,
                                child: Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.water_drop,
                                    size: 48,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PondStat',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.2),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Text(
                        _loadingMessages[_messageIndex],
                        key: ValueKey<int>(_messageIndex),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: const Text(
                      'For Fisheries Students',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}