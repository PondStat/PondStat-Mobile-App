import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/core/utils/helpers.dart';

class ManageCollaboratorsPage extends StatefulWidget {
  final String pondId;
  final String pondName;

  const ManageCollaboratorsPage({
    super.key,
    required this.pondId,
    required this.pondName,
  });

  @override
  State<ManageCollaboratorsPage> createState() =>
      _ManageCollaboratorsPageState();
}

class _ManageCollaboratorsPageState extends State<ManageCollaboratorsPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isAdding = false;

  final Map<String, Map<String, dynamic>> _userCache = {};

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);
  final Color textDark = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF64748B);
  final Color backgroundLight = const Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId]!;
    }

    try {
      final doc = await FirestoreHelper.usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _userCache[userId] = doc.data() as Map<String, dynamic>;
        return _userCache[userId]!;
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
    return {'fullName': 'Unknown User', 'email': 'No email found'};
  }

  Future<void> _inviteCollaborator() async {
    final email = _emailController.text.trim().toLowerCase();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      SnackbarHelper.show(
        context,
        'Please enter a valid email address.',
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => _isAdding = true);
    FocusScope.of(context).unfocus();

    try {
      final query = await FirestoreHelper.usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          SnackbarHelper.show(
            context,
            'User not found. They must sign up for PondStat first.',
            backgroundColor: Colors.orange.shade800,
          );
        }
        setState(() => _isAdding = false);
        return;
      }

      final targetUserId = query.docs.first.id;
      final pondRef = FirestoreHelper.pondsCollection.doc(widget.pondId);

      await pondRef.update({
        'memberIds': FieldValue.arrayUnion([targetUserId]),
        'roles.$targetUserId': 'viewer',
      });

      HapticFeedback.heavyImpact();
      _emailController.clear();

      if (mounted) {
        SnackbarHelper.show(
          context,
          'Collaborator added successfully!',
          backgroundColor: Colors.green.shade700,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          'Error adding collaborator: $e',
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _handleRoleChange(String userId, String newRole) {
    if (newRole == 'remove') {
      _showWarningDialog(
        title: "Remove Access?",
        content:
            "This user will immediately lose all access to this pond's data.",
        confirmText: "Remove",
        confirmColor: Colors.red,
        onConfirm: () => _updateRole(userId, 'remove'),
      );
    } else if (newRole == 'direct_remove') {
      _updateRole(userId, 'remove');
    } else if (newRole == 'owner') {
      _showWarningDialog(
        title: "Make Owner?",
        content:
            "This user will have full control over the pond, including the ability to delete the pond or remove your access.",
        confirmText: "Make Owner",
        confirmColor: Colors.orange.shade700,
        onConfirm: () => _updateRole(userId, 'owner'),
      );
    } else {
      _updateRole(userId, newRole);
    }
  }

  void _showWarningDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
    required VoidCallback onConfirm,
  }) {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded, color: confirmColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(color: textMuted, height: 1.4, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor.withValues(alpha: 0.1),
              foregroundColor: confirmColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRole(String userId, String newRole) async {
    final pondRef = FirestoreHelper.pondsCollection.doc(widget.pondId);

    try {
      if (newRole == 'remove') {
        await pondRef.update({
          'memberIds': FieldValue.arrayRemove([userId]),
          'roles.$userId': FieldValue.delete(),
        });
      } else {
        await pondRef.update({'roles.$userId': newRole});
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          'Failed to update role: $e',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isFocused = _emailFocus.hasFocus;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: textDark,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "SHARE POND",
                            style: TextStyle(
                              color: primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            widget.pondName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Invite Collaborator",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isFocused ? Colors.white : backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isFocused
                                    ? primaryBlue
                                    : Colors.grey.shade200,
                                width: isFocused ? 2 : 1,
                              ),
                              boxShadow: isFocused
                                  ? [
                                      BoxShadow(
                                        color: primaryBlue.withValues(
                                          alpha: 0.15,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: TextField(
                              controller: _emailController,
                              focusNode: _emailFocus,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _inviteCollaborator(),
                              style: TextStyle(
                                color: textDark,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: 'user@email.com',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                prefixIcon: Icon(
                                  Icons.email_rounded,
                                  color: isFocused
                                      ? primaryBlue
                                      : Colors.grey.shade400,
                                  size: 20,
                                ),
                                suffixIcon: _emailController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onPressed: () {
                                          HapticFeedback.selectionClick();
                                          _emailController.clear();
                                        },
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isAdding ? null : _inviteCollaborator,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isAdding
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people_alt_rounded,
                        color: primaryBlue,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "People with access",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirestoreHelper.pondsCollection
                      .doc(widget.pondId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load team members.',
                          style: TextStyle(color: Colors.red.shade400),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data =
                        snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    final roles = data['roles'] as Map<String, dynamic>? ?? {};

                    return ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 8,
                        bottom: 40,
                      ),
                      itemCount: roles.keys.length,
                      itemBuilder: (context, index) {
                        final userId = roles.keys.elementAt(index);
                        final role = roles[userId] as String;
                        final isMe = userId == currentUserId;

                        return CollaboratorTile(
                          key: ValueKey(userId),
                          pondId: widget.pondId,
                          userId: userId,
                          role: role,
                          isMe: isMe,
                          index: index,
                          onRoleChange: _handleRoleChange,
                          fetchUser: _getUserData,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                    userData?['fullName'] ?? 'U',
                  ).withValues(alpha: 0.2),
                  radius: 20,
                  child: Text(
                    StringUtils.getInitials(userData?['fullName'] ?? 'U'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getAvatarColor(userData?['fullName'] ?? 'U'),
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
                          color: Colors.blueGrey.shade900,
                        ),
                      ),
                      Text(
                        userData?['fullName'] ?? 'User',
                        style: TextStyle(
                          color: Colors.grey.shade600,
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
                      color: isDestructive ? color : Colors.blueGrey.shade900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
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
            color: Colors.white,
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

    final name = userData?['fullName'] ?? 'Unknown User';
    final email = userData?['email'] ?? '';
    final initials = StringUtils.getInitials(name);
    final avatarColor = widget.isMe
        ? const Color(0xFF0A74DA)
        : _getAvatarColor(name);

    Widget tileContent = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
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
        confirmDismiss: (direction) async {
          HapticFeedback.selectionClick();
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Colors.white,
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
                  const Expanded(
                    child: Text(
                      "Remove Access?",
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "This user will immediately lose all access to this pond's data.",
                style: TextStyle(
                  color: Color(0xFF64748B),
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
