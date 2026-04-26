import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _textController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Fish 125: Aquaculture Technologies',
      description:
          'Learn the basic operation of different culture systems, soil and water chemistry and its influence in productivity, pond management, production of natural food, nutrition and feeding, water quality management, site selection, design and construction of aquaculture facilities as well as harvest and post-harvest handling.',
      icon: Icons.school_rounded,
    ),
    OnboardingStep(
      title: 'Digital Pond Management',
      description:
          'A centralized system to organize individual pond profiles and keep track of core operational details such as species, stocking density, and target harvest date.',
      icon: Icons.space_dashboard_outlined,
    ),
    OnboardingStep(
      title: 'Environmental Data Logging',
      description:
          'Comprehensive tracking of daily, weekly, and biweekly parameters to maintain optimal pond health and identify environmental trends.',
      icon: Icons.analytics_outlined,
    ),
    OnboardingStep(
      title: 'Growth Performance Analytics',
      description:
          'Automated calculation of vital growth metrics including ABW, ADG, DFR, and FCR based on regular weekly sampling records.',
      icon: Icons.trending_up_rounded,
    ),
    OnboardingStep(
      title: 'Collaborative Workspace',
      description:
          'Share access with professors for academic review and assign specific operational roles to team members for efficient pond management.',
      icon: Icons.group_add_outlined,
    ),
  ];

  final AuthRepository _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutQuart),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textController.forward();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('hasSeenOnboarding') ?? false;
    if (hasSeen && mounted) {
      setState(() {
        _currentPage = _steps.length;
      });
      _pageController.jumpToPage(_steps.length);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authRepository.signInWithGoogle();

      if (userCredential == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Scaffold(
              body: Center(child: Text("Dashboard Placeholder")),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = "An unexpected error occurred. Please try again.";

        if (e is AuthException) {
          errorMessage = e.message;
        } else if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'network-request-failed':
              errorMessage =
                  "No internet connection. Please check your network.";
              break;
            case 'user-disabled':
              errorMessage =
                  "This account has been disabled. Please contact support.";
              break;
            case 'account-exists-with-different-credential':
              errorMessage =
                  "An account already exists with a different credential.";
              break;
            case 'invalid-credential':
              errorMessage = "Invalid credentials. Please try again.";
              break;
          }
        } else if (e is PlatformException) {
          errorMessage = "A platform error occurred during Sign-In.";
        }

        SnackbarHelper.show(
          context,
          errorMessage,
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                final t = _bubbleController.value;
                return Stack(
                  children: [
                    _buildBubble(
                      t,
                      screenSize.height * -0.05,
                      screenSize.width * -0.1,
                      screenSize.width * 0.45,
                      0,
                    ),
                    _buildBubble(
                      t,
                      screenSize.height * 0.1,
                      screenSize.width * 0.75,
                      screenSize.width * 0.25,
                      2,
                    ),
                    _buildBubble(
                      t,
                      screenSize.height * 0.5,
                      screenSize.width * -0.1,
                      screenSize.width * 0.35,
                      4,
                    ),
                    _buildBubble(
                      t,
                      screenSize.height * 0.6,
                      screenSize.width * 0.5,
                      screenSize.width * 0.2,
                      1.5,
                    ),
                    _buildBubble(
                      t,
                      screenSize.height * 0.25,
                      screenSize.width * 0.25,
                      screenSize.width * 0.15,
                      3.5,
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12.0),
                      const Text(
                        'PondStat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const Spacer(),
                      if (_currentPage < _steps.length)
                        TextButton(
                          onPressed: () {
                            _completeOnboarding();
                            _pageController.animateToPage(
                              _steps.length,
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeInOutQuart,
                            );
                          },
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _steps.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _steps.length) {
                        return _buildSignInPage(primaryColor);
                      }
                      return _buildOnboardingPage(_steps[index]);
                    },
                  ),
                ),
                _buildBottomControls(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24.0),
            ),
            child: Icon(step.icon, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 32.0),
          SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 4),
                          blurRadius: 10.0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16.0,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPage(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_person_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
          const SizedBox(height: 32.0),
          const Text(
            'Ready to Start?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Sign in with your UP mail account to access your pond dashboards and collaborate with your team.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16.0,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48.0),
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 56.0,
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signInWithGoogle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.8),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.0),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: primaryColor,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.google,
                          size: 22,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _steps.length + 1,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(right: 6),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: _currentPage == index ? 1.0 : 0.4,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          if (_currentPage < _steps.length)
            SizedBox(
              height: 56,
              width: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPage == _steps.length - 1) {
                    _completeOnboarding();
                  }
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  elevation: 4,
                ),
                child: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(
    double t,
    double top,
    double left,
    double size,
    double offset,
  ) {
    final x = 15 * math.cos(t * 2 * math.pi + offset);
    final y = 15 * math.sin(t * 2 * math.pi + offset);

    return Positioned(
      top: top + y,
      left: left + x,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
      ),
    );
  }
}
