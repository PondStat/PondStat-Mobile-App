import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pondstat/core/theme/app_theme.dart';
import 'package:pondstat/features/auth/presentation/auth_wrapper.dart';
import 'package:pondstat/core/widgets/loading_overlay.dart';
import 'package:pondstat/core/firebase/firebase_options.dart';
import 'package:pondstat/core/services/notification_service.dart';
import 'package:pondstat/core/services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load user settings early
  await SettingsService().loadSettings();

  // Initialize notifications (Mobile only)
  if (!kIsWeb) {
    await NotificationService().initialize();
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      try {
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        developer.log("✅ Offline persistence enabled");
      } catch (e) {
        developer.log("⚠️ Could not enable offline persistence: $e");
      }
    }

    developer.log("✅ Firebase connected successfully!");
  } catch (e) {
    developer.log("❌ Firebase connection failed: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        return MaterialApp(
          title: 'PondStat',
          debugShowCheckedModeBanner: false,
          themeMode: SettingsService().themeMode,
          theme: AppTheme.lightTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(
              AppTheme.lightTheme.textTheme,
            ),
            appBarTheme: AppBarTheme(
              titleTextStyle: GoogleFonts.poppins(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          darkTheme: AppTheme.darkTheme.copyWith(
            textTheme: GoogleFonts.interTextTheme(AppTheme.darkTheme.textTheme),
            appBarTheme: AppBarTheme(
              titleTextStyle: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AuthWrapper(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingOverlay();
  }
}
