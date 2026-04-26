import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/profile/presentation/edit_profile_page.dart';
import 'package:pondstat/features/profile/presentation/manage_collaborators_page.dart';
import 'package:pondstat/features/profile/presentation/settings_page.dart';

class ProfileBottomSheet extends StatefulWidget {
  final String? currentPondId;
  final String? currentPondName;
  final String? currentUserRole;

  const ProfileBottomSheet({
    super.key,
    this.currentPondId,
    this.currentPondName,
    this.currentUserRole,
  });

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet>
    with SingleTickerProviderStateMixin {
  final Color primaryBlue = const Color(0xFF0A74DA);

  late AnimationController _entranceController;
  late Animation<double> _fadeHeader;
  late Animation<double> _fadeCard;
  late Animation<double> _fadeButtons;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
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
    final User? user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              FadeTransition(
                opacity: _fadeHeader,
                child: SlideTransition(
                  position: _slideUp,
                  child: _buildUserInfo(user, theme, isDark),
                ),
              ),
              const SizedBox(height: 24),
              Divider(
                height: 1,
                color: isDark ? Colors.white12 : Colors.grey.shade100,
              ),
              const SizedBox(height: 24),

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
                            color: primaryBlue,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPondRoleCard(context, theme, isDark),
                        const SizedBox(height: 28),
                        Divider(
                          height: 1,
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],

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
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                          }
                        },
                      ),

                      if (widget.currentPondId != null &&
                          widget.currentUserRole == 'owner')
                        BouncyMenuButton(
                          icon: Icons.group_add_outlined,
                          text: 'Manage Collaborators',
                          onTap: () async {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                            await Future.delayed(
                              const Duration(milliseconds: 150),
                            );
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ManageCollaboratorsPage(
                                    pondId: widget.currentPondId!,
                                    pondName: widget.currentPondName ?? 'Pond',
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                      const SizedBox(height: 16),
                      _buildSectionHeader("PREFERENCES"),
                      BouncyMenuButton(
                        icon: Icons.settings_rounded,
                        text: 'App Settings',
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          await Future.delayed(
                            const Duration(milliseconds: 150),
                          );
                          if (context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsPage(),
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      _buildSectionHeader("ACTIONS"),
                      BouncyMenuButton(
                        icon: Icons.logout_rounded,
                        text: 'Sign Out',
                        isDestructive: true,
                        onTap: () => _confirmSignOut(context, theme, isDark),
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
          color: primaryBlue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildUserInfo(User? user, ThemeData theme, bool isDark) {
    final name = user?.displayName ?? 'PondStat User';
    final email = user?.email ?? 'No Email';
    final avatarColor = _getAvatarColor(name);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
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
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? Text(
                      StringUtils.getInitials(name),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: avatarColor,
                      ),
                    )
                  : null,
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
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
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

  Widget _buildPondRoleCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    IconData roleIcon = Icons.visibility_outlined;
    String roleTitle = 'Viewer';
    Color roleColor = theme.colorScheme.onSurfaceVariant;

    if (widget.currentUserRole == 'owner') {
      roleIcon = Icons.admin_panel_settings_rounded;
      roleTitle = 'Owner';
      roleColor = isDark ? Colors.orange.shade400 : Colors.orange.shade600;
    } else if (widget.currentUserRole == 'editor') {
      roleIcon = Icons.edit_note_rounded;
      roleTitle = 'Editor';
      roleColor = primaryBlue;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : roleColor.withValues(alpha: 0.15),
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

  Future<void> _confirmSignOut(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) async {
    HapticFeedback.selectionClick();
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
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
      if (context.mounted) Navigator.of(context).pop();
      await Future.delayed(const Duration(milliseconds: 150));
      try {
        await FirebaseAuth.instance.signOut();
        await GoogleSignIn().signOut();
      } catch (e) {
        debugPrint('Sign out error: $e');
      }
    }
  }
}

class BouncyMenuButton extends StatefulWidget {
  final IconData icon;
  final String text;
  final bool isDestructive;
  final VoidCallback onTap;

  const BouncyMenuButton({
    super.key,
    required this.icon,
    required this.text,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  State<BouncyMenuButton> createState() => _BouncyMenuButtonState();
}

class _BouncyMenuButtonState extends State<BouncyMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color itemColor = widget.isDestructive
        ? Colors.red.shade600
        : theme.colorScheme.onSurface;
    final Color iconBgColor = widget.isDestructive
        ? Colors.red.withValues(alpha: 0.1)
        : (isDark ? Colors.white12 : Colors.grey.shade100);
    final Color iconColor = widget.isDestructive
        ? Colors.red.shade600
        : theme.colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: itemColor,
                  ),
                ),
              ),
              if (!widget.isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
