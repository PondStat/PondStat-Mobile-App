import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_theme.dart';
import 'edit_profile_page.dart';
import 'manage_collaborators_page.dart';

class ProfileBottomSheet extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildUserInfo(user, theme),
              const SizedBox(height: 24),
              Divider(
                height: 1,
                color: theme.dividerColor,
              ),
              const SizedBox(height: 16),
              if (currentPondId != null && currentUserRole != null) ...[
                _buildPondRoleCard(context, theme),
                const SizedBox(height: 16),
              ],
              _buildMenuButton(
                icon: Icons.person_outline,
                text: 'Edit Profile',
                theme: theme,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
              ),
              if (currentPondId != null && currentUserRole == 'owner')
                _buildMenuButton(
                  icon: Icons.group_add_outlined,
                  text: 'Manage Collaborators',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageCollaboratorsPage(
                          pondId: currentPondId!,
                          pondName: currentPondName ?? 'Pond',
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              _buildMenuButton(
                icon: Icons.logout,
                text: 'Sign Out',
                isSignOut: true,
                theme: theme,
                onTap: () => _confirmSignOut(context, theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(User? user, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.primary.withOpacity(0.1),
          backgroundImage: user?.photoURL != null
              ? NetworkImage(user!.photoURL!)
              : null,
          child: user?.photoURL == null
              ? Icon(
                  Icons.person,
                  size: 32,
                  color: colorScheme.primary,
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'PondStat User',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? 'No Email',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPondRoleCard(BuildContext context, ThemeData theme) {
    final statusColors = theme.extension<PondStatusColors>();

    IconData roleIcon = Icons.visibility_outlined;
    String roleTitle = 'Viewer';
    Color roleColor = theme.colorScheme.onSurfaceVariant;

    if (currentUserRole == 'owner') {
      roleIcon = Icons.verified_user_outlined;
      roleTitle = 'Owner';
      roleColor = statusColors?.healthy ?? Colors.green;
    } else if (currentUserRole == 'editor') {
      roleIcon = Icons.edit_note;
      roleTitle = 'Editor';
      roleColor = theme.colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: roleColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            roleIcon,
            color: roleColor,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access: $currentPondName',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  roleTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required ThemeData theme,
    bool isSignOut = false,
    required VoidCallback onTap,
  }) {
    final colorScheme = theme.colorScheme;
    final Color itemColor =
        isSignOut ? colorScheme.error : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: itemColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: itemColor,
            size: 22,
          ),
        ),
        title: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        trailing: isSignOut
            ? null
            : Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, ThemeData theme) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(
            'Sign Out',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          content: Text(
            'Are you sure you want to sign out of PondStat?',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      if (context.mounted) {
        Navigator.of(context).pop();
      }

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