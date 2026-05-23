import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/core/utils/string_extensions.dart';

class CollaboratorTile extends StatefulWidget {
  final String pondId;
  final String userId;
  final String role;
  final bool isMe;
  final int index;
  final Function(String, String) onRoleChange;
  final Future<Map<String, dynamic>> Function(String) fetchUser;

  const CollaboratorTile({
    super.key,
    required this.pondId,
    required this.userId,
    required this.role,
    required this.isMe,
    required this.index,
    required this.onRoleChange,
    required this.fetchUser,
  });

  @override
  State<CollaboratorTile> createState() => _CollaboratorTileState();
}

class _CollaboratorTileState extends State<CollaboratorTile>
    with TickerProviderStateMixin {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  late AnimationController _shimmerController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutQuart,
          ),
        );

    _loadUser();
  }

  @override
  void didUpdateWidget(covariant CollaboratorTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.userId != widget.userId) {
      setState(() => isLoading = true);
      _loadUser();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final data = await widget.fetchUser(widget.userId);
    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });

      Future.delayed(Duration(milliseconds: 50 * widget.index), () {
        if (mounted) _entranceController.forward();
      });
    }
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

  void _showRoleSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.only(
            bottom: 32,
            top: 12,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getAvatarColor(
                      (userData?['fullName']?.toString().trim().isEmpty ?? true)
                          ? 'U'
                          : userData!['fullName'],
                    ).withValues(alpha: 0.2),
                    radius: 20,
                    child: Text(
                      (userData?['fullName'] as String?).initials,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getAvatarColor(
                          (userData?['fullName']?.toString().trim().isEmpty ??
                                  true)
                              ? 'U'
                              : userData!['fullName'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Manage Access",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          userData?['fullName'] ?? 'User',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildRoleOption(
                'viewer',
                'Viewer',
                'Can view pond data and measurements.',
                Icons.visibility_rounded,
                Colors.grey.shade700,
              ),
              _buildRoleOption(
                'editor',
                'Editor',
                'Can add, edit, and manage measurements.',
                Icons.edit_rounded,
                Colors.blue.shade700,
              ),
              _buildRoleOption(
                'owner',
                'Owner',
                'Full control. Can delete the pond and manage users.',
                Icons.admin_panel_settings_rounded,
                Colors.orange.shade700,
              ),
              const Divider(height: 32),
              _buildRoleOption(
                'remove',
                'Remove Access',
                'Revoke all access immediately.',
                Icons.person_remove_rounded,
                Colors.red.shade600,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleOption(
    String roleId,
    String title,
    String description,
    IconData icon,
    Color color, {
    bool isDestructive = false,
  }) {
    final isSelected = widget.role == roleId;

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) widget.onRoleChange(widget.userId, roleId);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.05)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isDestructive ? color : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return FadeTransition(
        opacity: Tween<double>(
          begin: 0.4,
          end: 1.0,
        ).animate(_shimmerController),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 14,
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final rawName = userData?['fullName']?.toString().trim() ?? '';
    final name = rawName.isEmpty ? 'Unknown User' : rawName;
    final email = userData?['email'] ?? '';
    final initials = name.initials;
    final avatarColor = widget.isMe
        ? const Color(0xFF0A74DA)
        : _getAvatarColor(name);

    Widget tileContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: avatarColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: widget.isMe
                ? avatarColor
                : avatarColor.withValues(alpha: 0.2),
            child: Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: widget.isMe ? Colors.white : avatarColor,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          widget.isMe ? "$name (You)" : name,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.isMe
                ? Tooltip(
                    message: 'You cannot change your own role',
                    triggerMode: TooltipTriggerMode.tap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        widget.role.toUpperCase(),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  )
                : InkWell(
                    onTap: () => _showRoleSelector(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.role.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_more_rounded,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );

    Widget animatedTile = FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: tileContent),
    );

    if (!widget.isMe) {
      return Dismissible(
        key: Key("dismiss_${widget.userId}"),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade500,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.delete_sweep_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        onUpdate: (details) {
          if (details.reached && !details.previousReached) {
            HapticFeedback.lightImpact();
          }
        },
        confirmDismiss: (direction) async {
          HapticFeedback.selectionClick();
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
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
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Remove Access?",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                "This user will immediately lose all access to this pond's data.",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontSize: 15,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    "Cancel",
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
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    "Remove",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) {
          widget.onRoleChange(widget.userId, 'direct_remove');
        },
        child: animatedTile,
      );
    }

    return animatedTile;
  }
}
