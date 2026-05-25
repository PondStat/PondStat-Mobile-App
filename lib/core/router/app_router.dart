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
import 'package:pondstat/features/chat/presentation/pond_chat_page.dart';
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
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const DefaultDashboardScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.auth,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomePage(),
          transitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) => _buildSlideUpPage(state, const NotificationsInboxPage()),
      ),
      GoRoute(
        path: AppRoutes.settings,
        pageBuilder: (context, state) => _buildSlideUpPage(state, const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        pageBuilder: (context, state) => _buildSlideUpPage(state, const EditProfilePage()),
      ),
      GoRoute(
        path: AppRoutes.pond,
        pageBuilder: (context, state) {
          final pondId = state.pathParameters['pondId']!;
          final Widget child;

          // Option A: data passed via `extra` (in-app navigation)
          final extra = state.extra;
          if (extra is Pond) {
            final user = authRepo.currentUser;
            final userRole = extra.roles[user?.uid] ?? 'viewer';
            child = PondMonitoringScaffold(
              pondId: pondId,
              pondName: extra.name.isNotEmpty ? extra.name : 'Unnamed Pond',
              userRole: userRole,
              species: extra.species.isNotEmpty ? extra.species : 'Unspecified',
              createdAt: extra.createdAt ?? DateTime.now(),
              targetCulturePeriodDays:
                  extra.targetCulturePeriodDays > 0 ? extra.targetCulturePeriodDays : 90,
            );
          } else if (extra is Map<String, dynamic>) {
            // Option B: extra contains a Map with pre-extracted fields
            child = PondMonitoringScaffold(
              pondId: pondId,
              pondName: extra['pondName'] as String? ?? 'Unnamed Pond',
              userRole: extra['userRole'] as String? ?? 'viewer',
              species: extra['species'] as String? ?? 'Unspecified',
              createdAt: extra['createdAt'] as DateTime? ?? DateTime.now(),
              targetCulturePeriodDays:
                  extra['targetCulturePeriodDays'] as int? ?? 90,
            );
          } else {
            // Option C: deep link without data (e.g. from notification)
            child = _DeepLinkPondLoader(pondId: pondId);
          }

          // Slide from right — drill-down feel
          return _buildSlideRightPage(state, child);
        },
        routes: [
          GoRoute(
            path: 'collaborators',
            pageBuilder: (context, state) {
              final pondId = state.pathParameters['pondId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return _buildSlideUpPage(
                state,
                ManageCollaboratorsPage(
                  pondId: pondId,
                  pondName: extra?['pondName'] as String? ?? 'Pond',
                ),
              );
            },
          ),
          GoRoute(
            path: 'chat',
            pageBuilder: (context, state) {
              final pondId = state.pathParameters['pondId']!;
              final extra = state.extra as Map<String, dynamic>?;
              return _buildSlideRightPage(
                state,
                PondChatPage(
                  pondId: pondId,
                  pondName: extra?['pondName'] as String? ?? 'Pond',
                  userRole: extra?['userRole'] as String? ?? 'viewer',
                ),
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

// ── Page Transition Helpers ─────────────────────────────────────────────────

/// Slide-from-bottom transition (300ms) — used for modal-like routes
/// (notifications, settings, edit profile, collaborators).
CustomTransitionPage<void> _buildSlideUpPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.5)),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Slide-from-right transition (350ms, easeInOutCubic) — used for
/// drill-down navigation (pond → monitoring scaffold).
CustomTransitionPage<void> _buildSlideRightPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
        reverseCurve: Curves.easeInOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    },
  );
}

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
