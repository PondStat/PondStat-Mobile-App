import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/theme/app_theme.dart';
import 'package:pondstat/features/auth/presentation/auth_wrapper.dart';
import 'package:pondstat/core/firebase/firebase_options.dart';
import 'package:pondstat/core/services/notification_service.dart';
import 'package:pondstat/core/services/settings_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  String? initializationError;

  try {
    // Load user settings early
    await SettingsService().loadSettings();

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

    // Initialize notifications (Mobile only)
    if (!kIsWeb) {
      await NotificationService().initialize();
    }
  } catch (e, stackTrace) {
    developer.log(
      "❌ Initialization failed: $e",
      error: e,
      stackTrace: stackTrace,
    );
    initializationError = e.toString();
  } finally {
    FlutterNativeSplash.remove();
  }

  runApp(ProviderScope(child: MyApp(initializationError: initializationError)));
}

class MyApp extends StatelessWidget {
  final String? initializationError;

  const MyApp({super.key, this.initializationError});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final themeMode = SettingsService().themeMode;

        return MaterialApp(
          title: 'PondStat',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: initializationError != null
              ? ErrorApp(error: initializationError!)
              : const AuthWrapper(),
        );
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // A simple restart requires app to be closed and opened again
                  // We provide a visual hint for the user
                },
                child: const Text('Please restart the application'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
