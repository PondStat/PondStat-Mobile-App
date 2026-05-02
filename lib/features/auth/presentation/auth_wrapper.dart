import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/dashboard/presentation/default_dashboard.dart';
import 'package:pondstat/features/auth/presentation/welcome_page.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthRepository().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const DefaultDashboardScreen();
        }

        return const WelcomePage();
      },
    );
  }
}
