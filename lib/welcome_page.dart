import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'firebase/firestore_helper.dart';
import 'utility/helpers.dart';
import 'firebase/user_log_helper.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late AnimationController _bubbleController;
  late AnimationController _textController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;

  final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '624574025589-5390binsi9sh8plk6ii0h929dtq63dvu.apps.googleusercontent.com',
      );

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

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
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

        await UserLogHelper.logAction(
          action: 'login',
          entityType: 'auth',
        );

        if (mounted) {
          setState(() => _isLoading = false);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text("Dashboard Placeholder"),
                ),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMessage = "An unexpected error occurred. Please try again.";

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'network-request-failed':
              errorMessage = "No internet connection. Please check your network.";
              break;
            case 'user-disabled':
              errorMessage = "This account has been disabled. Please contact support.";
              break;
            case 'account-exists-with-different-credential':
              errorMessage = "An account already exists with a different credential.";
              break;
            case 'invalid-credential':
              errorMessage = "Invalid credentials. Please try again.";
              break;
          }
        } else if (e is PlatformException) {
          if (e.code == GoogleSignIn.kNetworkError) {
            errorMessage = "A network error occurred during Google Sign-In.";
          }
        }

        SnackbarHelper.show(context, errorMessage, backgroundColor: Colors.redAccent);
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
                colors: [
                  primaryColor,
                  primaryColor.withOpacity(0.8),
                ],
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
                    _buildBubble(t, screenSize.height * -0.05, screenSize.width * -0.1, screenSize.width * 0.45, 0),
                    _buildBubble(t, screenSize.height * 0.1, screenSize.width * 0.75, screenSize.width * 0.25, 2),
                    _buildBubble(t, screenSize.height * 0.5, screenSize.width * -0.1, screenSize.width * 0.35, 4),
                    _buildBubble(t, screenSize.height * 0.6, screenSize.width * 0.5, screenSize.width * 0.2, 1.5),
                    _buildBubble(t, screenSize.height * 0.25, screenSize.width * 0.25, screenSize.width * 0.15, 3.5),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      child: Column(
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: double.infinity,
                              minHeight: 54.0,
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                disabledBackgroundColor: Colors.white.withOpacity(0.8),
                                elevation: 3,
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
                          const SizedBox(height: 24.0),
                          Text(
                            "By continuing, you agree to our Terms of Service\nand Privacy Policy.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                        ],
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

  Widget _buildBubble(double t, double top, double left, double size, double offset) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
      ),
    );
  }
}