/// Centralized route path constants to prevent typos and enable refactoring.
///
/// Usage:
/// ```dart
/// context.push(AppRoutes.notifications);
/// context.push(AppRoutes.pondPath(pondId));
/// ```
class AppRoutes {
  AppRoutes._();

  static const String dashboard = '/';
  static const String auth = '/auth';
  static const String notifications = '/notifications';
  static const String settings = '/settings';
  static const String editProfile = '/profile/edit';

  /// Parameterized route: `/pond/:pondId`
  static const String pond = '/pond/:pondId';

  /// Parameterized route: `/pond/:pondId/collaborators`
  static const String collaborators = '/pond/:pondId/collaborators';

  /// Parameterized route: `/pond/:pondId/chat`
  static const String chat = '/pond/:pondId/chat';

  // ─── Path Builders ────────────────────────────────────────────────────

  /// Returns `/pond/<id>` with the actual pond ID substituted.
  static String pondPath(String pondId) => '/pond/$pondId';

  /// Returns `/pond/<id>/collaborators` with the actual pond ID substituted.
  static String collaboratorsPath(String pondId) =>
      '/pond/$pondId/collaborators';

  /// Returns `/pond/<id>/chat` with the actual pond ID substituted.
  static String chatPath(String pondId) => '/pond/$pondId/chat';
}
