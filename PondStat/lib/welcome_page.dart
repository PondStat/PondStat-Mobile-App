import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_helper.dart';

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

  @override
  void initState() {
    super.initState();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOutQuart,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textController.forward();
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _signInWithGoogle() async {
    _showLoading();

    try {
      // 1. ADD YOUR CLIENT ID HERE
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '624574025589-5390binsi9sh8plk6ii0h929dtq63dvu.apps.googleusercontent.com', 
      );
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) _hideLoading();
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final userDoc = await FirestoreHelper.usersCollection.doc(user.uid).get();

        if (!userDoc.exists) {
          await FirestoreHelper.usersCollection.doc(user.uid).set({
            'fullName': user.displayName ?? 'New User',
            'email': user.email,
            'role': 'member',
            'assignedPond': null,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        _hideLoading();
      }
    } catch (e) {
      if (mounted) {
        _hideLoading();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Sign-In failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // Animated Bubbles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                final t = _bubbleController.value;
                return Stack(
                  children: [
                    _buildBubble(t, -50, -50, 180, 0),
                    _buildBubble(t, 80, 300, 100, 2),
                    _buildBubble(t, 400, -50, 140, 4),
                    _buildBubble(t, 500, 200, 80, 1.5),
                    _buildBubble(t, 200, 100, 60, 3.5),
                  ],
                );
              },
            ),
          ),

          // Foreground Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo/Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
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
                    ],
                  ),

                  const Spacer(),

                  // Animated Text & Buttons
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Pond Monitoring',
                            style: TextStyle(
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
                          const SizedBox(height: 12.0),
                          Text(
                            'Real-time analytics for your aquaculture.\nTrack parameters, manage teams, and boost production.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15.0,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40.0),

                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // Google Sign-In Button
                            SizedBox(
                              width: double.infinity,
                              height: 54.0,
                              child: ElevatedButton.icon(
                                onPressed: _signInWithGoogle,
                                icon: const Icon(Icons.login, size: 22),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: primaryColor,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40.0),
                          ],
                        ),
                      ),
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
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}