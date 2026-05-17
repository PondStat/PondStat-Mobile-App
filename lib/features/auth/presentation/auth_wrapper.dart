import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/dashboard/presentation/default_dashboard.dart';
import 'package:pondstat/features/auth/presentation/welcome_page.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/core/widgets/loading_overlay.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: ref.watch(authRepositoryProvider).authStateChanges,
      builder: (context, snapshot) {
        Widget currentWidget;

        if (snapshot.connectionState == ConnectionState.waiting) {
          currentWidget = const LoadingOverlay(
            messages: ['Checking access...'],
          );
        } else if (snapshot.hasError) {
          currentWidget = Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Authentication Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        } else if (snapshot.hasData) {
          currentWidget = const DefaultDashboardScreen();
        } else {
          currentWidget = const WelcomePage();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          child: KeyedSubtree(
            key: ValueKey<int>(
              snapshot.connectionState == ConnectionState.waiting
                  ? 0
                  : snapshot.hasError
                  ? 1
                  : snapshot.hasData
                  ? 2
                  : 3,
            ),
            child: currentWidget,
          ),
        );
      },
    );
  }
}
