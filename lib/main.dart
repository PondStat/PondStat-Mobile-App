import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/core/theme/app_theme.dart';
import 'package:pondstat/features/auth/presentation/auth_wrapper.dart';
import 'package:pondstat/core/firebase/firebase_options.dart';
import 'package:pondstat/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pondstat/core/services/settings/settings_provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pondstat/core/widgets/loading_overlay.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: 'PondStat',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  String? _initializationError;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
    _initializeApp();
  }

  Future<void> _initializeApp() async {
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
          ref.read(appLoggerProvider).info('Offline persistence enabled', tag: 'FIREBASE');
        } catch (e) {
          ref.read(appLoggerProvider).warning('Could not enable offline persistence: $e', tag: 'FIREBASE');
        }
      }

      ref.read(appLoggerProvider).info('Firebase connected successfully!', tag: 'FIREBASE');

      // Initialize Crashlytics for production error tracking
      if (!kIsWeb) {
        if (!kDebugMode) {
          // Pass all uncaught Flutter errors to Crashlytics
          FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
          // Pass all uncaught async errors to Crashlytics
          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true;
          };
        }
        // Disable Crashlytics data collection in debug to avoid noise
        await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
      }

      if (!kIsWeb) {
        await ref.read(notificationServiceProvider).initialize();
      }

      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e, stackTrace) {
      final log = ref.read(appLoggerProvider);
      log.error(
        'App initialization failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'STARTUP',
      );
      if (mounted) {
        setState(() {
          _initializationError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializationError != null) {
      return ErrorApp(error: _initializationError!);
    }

    if (_isInitialized) {
      return const AuthWrapper();
    }

    return const LoadingOverlay();
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
                'Connection Error',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We are having trouble connecting to the servers. Please check your internet connection and try again.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.exit_to_app_rounded),
                onPressed: () {
                  SystemNavigator.pop();
                },
                label: const Text('Exit App'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
