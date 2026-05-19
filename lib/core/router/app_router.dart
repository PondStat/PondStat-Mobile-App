import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/router/route_names.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/auth/presentation/welcome_page.dart';
import 'package:pondstat/features/dashboard/presentation/default_dashboard.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/features/monitoring/presentation/pond_monitoring_scaffold.dart';
import 'package:pondstat/features/notifications/presentation/notifications_inbox_page.dart';
import 'package:pondstat/features/profile/presentation/edit_profile_page.dart';
import 'package:pondstat/features/profile/presentation/settings_page.dart';
import 'package:pondstat/features/profile/presentation/manage_collaborators_page.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/core/services/notification_service.dart';

/// A [ChangeNotifier] that listens to Firebase Auth state changes and
/// notifies GoRouter to re-evaluate its redirect logic.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(Stream<User?> authStream) {
    _subscription = authStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Riverpod provider for the app's [GoRouter] instance.
///
/// This is the single source of truth for all routing in the app.
/// Bottom sheets and dialogs are NOT managed by GoRouter — they remain
/// imperative via `showModalBottomSheet` / `showDialog`.
final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final authNotifier = AuthNotifier(authRepo.authStateChanges);
  ref.onDispose(() => authNotifier.dispose());

  final router = GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: authNotifier,

    // ── Auth Redirect Guard ──────────────────────────────────────────────
    redirect: (context, state) {
      final isLoggedIn = authRepo.currentUser != null;
      final isGoingToAuth = state.matchedLocation == AppRoutes.auth;

      // Not logged in → force to auth (unless already there)
      if (!isLoggedIn && !isGoingToAuth) {
        return AppRoutes.auth;
      }

      // Logged in but going to auth → redirect to dashboard
      if (isLoggedIn && isGoingToAuth) {
        return AppRoutes.dashboard;
      }

      // No redirect needed
      return null;
    },

    // ── Route Definitions ────────────────────────────────────────────────
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DefaultDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsInboxPage(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.pond,
        builder: (context, state) {
          final pondId = state.pathParameters['pondId']!;

          // Option A: data passed via `extra` (in-app navigation)
          final extra = state.extra;
          if (extra is Pond) {
            final user = authRepo.currentUser;
            final userRole = extra.roles[user?.uid] ?? 'viewer';
            return PondMonitoringScaffold(
              pondId: pondId,
              pondName: extra.name.isNotEmpty ? extra.name : 'Unnamed Pond',
              userRole: userRole,
              species: extra.species.isNotEmpty ? extra.species : 'Unspecified',
              createdAt: extra.createdAt ?? DateTime.now(),
              targetCulturePeriodDays:
                  extra.targetCulturePeriodDays > 0 ? extra.targetCulturePeriodDays : 90,
            );
          }

          // Option B: extra contains a Map with pre-extracted fields
          // (used from PondListCard where we have all fields ready)
          if (extra is Map<String, dynamic>) {
            return PondMonitoringScaffold(
              pondId: pondId,
              pondName: extra['pondName'] as String? ?? 'Unnamed Pond',
              userRole: extra['userRole'] as String? ?? 'viewer',
              species: extra['species'] as String? ?? 'Unspecified',
              createdAt: extra['createdAt'] as DateTime? ?? DateTime.now(),
              targetCulturePeriodDays:
                  extra['targetCulturePeriodDays'] as int? ?? 90,
            );
          }

          // Option C: deep link without data (e.g. from notification)
          // Show a lightweight loading scaffold that fetches pond data.
          return _DeepLinkPondLoader(pondId: pondId);
        },
        routes: [
          GoRoute(
            path: 'collaborators',
            builder: (context, state) {
              final pondId = state.pathParameters['pondId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ManageCollaboratorsPage(
                pondId: pondId,
                pondName: extra?['pondName'] as String? ?? 'Pond',
              );
            },
          ),
        ],
      ),
    ],

    // ── Error Page ─────────────────────────────────────────────────────
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.matchedLocation,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Inject router into NotificationService for deep-link tap handling
  ref.read(notificationServiceProvider).router = router;

  return router;
});

/// A fallback widget for when a pond route is accessed via deep link
/// without `extra` data. Loads the pond from Firestore by ID.
class _DeepLinkPondLoader extends ConsumerWidget {
  final String pondId;
  const _DeepLinkPondLoader({required this.pondId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepo = ref.watch(authRepositoryProvider);
    final user = authRepo.currentUser;

    return FutureBuilder<Pond?>(
      future: _loadPond(ref, pondId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final pond = snapshot.data;
        if (pond == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.water_drop_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pond not found',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final userRole = pond.roles[user?.uid] ?? 'viewer';
        return PondMonitoringScaffold(
          pondId: pond.id,
          pondName: pond.name.isNotEmpty ? pond.name : 'Unnamed Pond',
          userRole: userRole,
          species: pond.species.isNotEmpty ? pond.species : 'Unspecified',
          createdAt: pond.createdAt ?? DateTime.now(),
          targetCulturePeriodDays:
              pond.targetCulturePeriodDays > 0 ? pond.targetCulturePeriodDays : 90,
        );
      },
    );
  }

  Future<Pond?> _loadPond(WidgetRef ref, String pondId) async {
    try {
      final doc = await ref
          .read(pondRepositoryProvider)
          .pondsCollection
          .doc(pondId)
          .get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }
}
