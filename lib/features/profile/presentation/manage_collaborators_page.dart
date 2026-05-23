import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/profile/presentation/widgets/collaborator_tile.dart';

class ManageCollaboratorsPage extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;

  const ManageCollaboratorsPage({
    super.key,
    required this.pondId,
    required this.pondName,
  });

  @override
  ConsumerState<ManageCollaboratorsPage> createState() =>
      _ManageCollaboratorsPageState();
}

class _ManageCollaboratorsPageState extends ConsumerState<ManageCollaboratorsPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  bool _isAdding = false;

  final Map<String, Map<String, dynamic>> _userCache = {};

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get backgroundLight => Theme.of(context).scaffoldBackgroundColor;

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
      final doc = await ref.read(authRepositoryProvider).usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        _userCache[userId] = doc.data() as Map<String, dynamic>;
        return _userCache[userId]!;
      }
    } catch (e, stackTrace) {
      ref.read(appLoggerProvider).error("Error fetching user", error: e, stackTrace: stackTrace, tag: 'COLLABORATORS');
    }
    return {'fullName': 'Unknown User', 'email': 'No email found'};
  }

  Future<void> _inviteCollaborator() async {
    final emailInput = _emailController.text.trim();
    final emailLowercase = emailInput.toLowerCase();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (emailInput.isEmpty || !emailRegex.hasMatch(emailInput)) {
      SnackbarHelper.showInfo(context, 'Please enter a valid email address.');
      return;
    }

    setState(() => _isAdding = true);
    FocusScope.of(context).unfocus();

    // Capture providers before any async gap to avoid Riverpod ref access after unmount.
    final authRepo = ref.read(authRepositoryProvider);
    final pondRepo = ref.read(pondRepositoryProvider);

    try {
      var query = await authRepo.usersCollection
          .where('email', isEqualTo: emailLowercase)
          .limit(1)
          .get();

      if (!mounted) return;

      // Fallback: If not found, and the original input had capital letters, query by the exact casing.
      if (query.docs.isEmpty && emailInput != emailLowercase) {
        query = await authRepo.usersCollection
            .where('email', isEqualTo: emailInput)
            .limit(1)
            .get();
        
        if (!mounted) return;
      }

      if (query.docs.isEmpty) {
        SnackbarHelper.showInfo(context, 'User not found. They must sign up for PondStat first.');
        setState(() => _isAdding = false);
        return;
      }

      final targetUserId = query.docs.first.id;
      final pondRef = pondRepo.pondsCollection.doc(widget.pondId);

      await pondRef.update({
        'memberIds': FieldValue.arrayUnion([targetUserId]),
        'roles.$targetUserId': 'viewer',
      });

      if (!mounted) return;

      HapticFeedback.heavyImpact();
      _emailController.clear();
      SnackbarHelper.showSuccess(context, 'Collaborator added successfully!');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Error adding collaborator: $e');
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
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
            child: Text(
              "Cancel",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
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
    final pondRef = ref.read(pondRepositoryProvider).pondsCollection.doc(widget.pondId);

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
        SnackbarHelper.showError(context, 'Failed to update role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
                          color: Theme.of(context).colorScheme.surface,
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
                  color: Theme.of(context).colorScheme.surface,
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: PondStatTextField(
                            controller: _emailController,
                            focusNode: _emailFocus,
                            label: 'Collaborator Email',
                            hint: 'user@up.edu.ph',
                            prefixIcon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _inviteCollaborator(),
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
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isAdding ? null : _inviteCollaborator,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
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
                child: StreamBuilder<DocumentSnapshot<Pond>>(
                  stream: ref.read(pondRepositoryProvider).pondsCollection
                      .doc(widget.pondId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorStateCard(
                        description: "Unable to load team members: ${snapshot.error}",
                        onRetry: () => setState(() {}),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const LoadingPlaceholder(message: "Loading team members...");
                    }

                    final pond = snapshot.data!.data();
                    final roles = pond?.roles ?? {};

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


