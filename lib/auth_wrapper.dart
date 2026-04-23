import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard/default_dashboard.dart';
import '../welcome_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const DefaultDashboardScreen();
        }

        return const WelcomePage();
      },
    );
  }
}
