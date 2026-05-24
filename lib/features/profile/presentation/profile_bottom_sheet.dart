import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:pondstat/core/utils/string_extensions.dart';
import 'package:pondstat/core/router/route_names.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:pondstat/features/profile/presentation/widgets/bouncy_menu_button.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';

class ProfileBottomSheet extends ConsumerStatefulWidget {
  final String? currentPondId;
  final String? currentPondName;
  final String? currentUserRole;
  final bool startCollaboratorTour;

  const ProfileBottomSheet({
    super.key,
    this.currentPondId,
    this.currentPondName,
    this.currentUserRole,
    this.startCollaboratorTour = false,
  });

  @override
  ConsumerState<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends ConsumerState<ProfileBottomSheet>
    with SingleTickerProviderStateMixin {

  late AnimationController _entranceController;
  late Animation<double> _fadeHeader;
  late Animation<double> _fadeCard;
  late Animation<double> _fadeButtons;
  late Animation<Offset> _slideUp;

  final GlobalKey _collaboratorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ShowcaseView.register();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeHeader = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _fadeCard = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );
    _fadeButtons = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );

    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.startCollaboratorTour && widget.currentUserRole == 'owner') {
        // Wait slightly for the modal sheets entrance slide animation to complete
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) {
            ShowcaseView.get().startShowCase([_collaboratorKey]);
            ref.read(onboardingTourProvider.notifier).markCollaboratorsAsSeen();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    _entranceController.dispose();
    super.dispose();
  }

  Color _getAvatarColor(String name) {
    final pastelColors = [
      const Color(0xFFFDA4AF),
      const Color(0xFFFCD34D),
      const Color(0xFF6EE7B7),
      const Color(0xFF93C5FD),
      const Color(0xFFC4B5FD),
      const Color(0xFFF9A8D4),
      const Color(0xFFFDBA74),
      const Color(0xFF5EEAD4),
    ];
    final hash = name.hashCode.abs();
    return pastelColors[hash % pastelColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userChangesProvider);
    final User? user = userAsync.value ?? FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // User Info
              FadeTransition(
                opacity: _fadeHeader,
                child: SlideTransition(
                  position: _slideUp,
                  child: _buildUserInfo(user, theme),
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),

              // Current Workspace / Pond info
              if (widget.currentPondId != null &&
                  widget.currentUserRole != null) ...[
                FadeTransition(
                  opacity: _fadeCard,
                  child: SlideTransition(
                    position: _slideUp,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "CURRENT WORKSPACE",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPondRoleCard(context, theme),
                        const SizedBox(height: 28),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],

              // Menu Options
              FadeTransition(
                opacity: _fadeButtons,
                child: SlideTransition(
                  position: _slideUp,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("ACCOUNT & WORKSPACE"),
                      BouncyMenuButton(
                        icon: Icons.person_outline_rounded,
                        text: 'Edit Profile',
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.editProfile);
                        },
                      ),

                      if (widget.currentPondId != null &&
                          widget.currentUserRole == 'owner')
                        CustomShowcase(
                          showcaseKey: _collaboratorKey,
                          title: "Manage Pond Collaborators",
                          description: "Invite and manage farm hands, editors, or other viewers to help you monitor this pond's parameters together!",
                          child: BouncyMenuButton(
                            icon: Icons.group_add_outlined,
                            text: 'Manage Collaborators',
                            onTap: () {
                              Navigator.pop(context);
                              context.push(
                                AppRoutes.collaboratorsPath(widget.currentPondId!),
                                extra: <String, dynamic>{
                                  'pondName': widget.currentPondName ?? 'Pond',
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),
                      _buildSectionHeader("PREFERENCES"),
                      BouncyMenuButton(
                        icon: Icons.settings_rounded,
                        text: 'App Settings',
                        onTap: () {
                          Navigator.pop(context);
                          context.push(AppRoutes.settings);
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildSectionHeader("ACTIONS"),
                      BouncyMenuButton(
                        icon: Icons.logout_rounded,
                        text: 'Sign Out',
                        isDestructive: true,
                        onTap: () => _confirmSignOut(context, theme),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserInfo(User? user, ThemeData theme) {
    final name = user?.displayName ?? 'PondStat User';
    final email = user?.email ?? 'No Email';
    final avatarColor = _getAvatarColor(name);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: avatarColor.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: avatarColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 32,
              backgroundColor: avatarColor.withValues(alpha: 0.15),
              child: user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(color: avatarColor);
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            name.initials,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: avatarColor,
                            ),
                          );
                        },
                      ),
                    )
                  : Text(
                      name.initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: avatarColor,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPondRoleCard(BuildContext context, ThemeData theme) {
    IconData roleIcon = Icons.visibility_outlined;
    String roleTitle = 'Viewer';
    Color roleColor = theme.colorScheme.onSurfaceVariant;

    if (widget.currentUserRole == 'owner') {
      roleIcon = Icons.admin_panel_settings_rounded;
      roleTitle = 'Owner';
      roleColor = theme.brightness == Brightness.dark
          ? Colors.orange.shade400
          : Colors.orange.shade600;
    } else if (widget.currentUserRole == 'editor') {
      roleIcon = Icons.edit_note_rounded;
      roleTitle = 'Editor';
      roleColor = theme.colorScheme.primary;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? Colors.white12
              : roleColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  roleColor.withValues(alpha: 0.15),
                  roleColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.2)),
            ),
            child: Icon(roleIcon, color: roleColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentPondName ?? 'Unknown Pond',
                  style: TextStyle(
                    fontSize: 17,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: roleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, ThemeData theme) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to sign out of PondStat?',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
              fontSize: 15,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                HapticFeedback.heavyImpact();
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      final logger = ref.read(appLoggerProvider);
      if (context.mounted) Navigator.of(context).pop();
      try {
        await ref.read(authRepositoryProvider).signOut();
      } catch (e, stackTrace) {
        logger.error("Sign out error", error: e, stackTrace: stackTrace, tag: 'AUTH');
      }
    }
  }
}
