import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';

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
  bool _isAdding = false;

  final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void dispose() {
    _emailController.dispose();
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
    return {
      'fullName': 'Unknown User',
      'email': 'No email found',
    };
  }

  Future<void> _inviteCollaborator() async {
    final email = _emailController.text.trim().toLowerCase();

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      SnackbarHelper.show(context, 'Please enter a valid email address.', backgroundColor: Colors.orange);
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
          SnackbarHelper.show(context, 'User not found. They must sign up for PondStat first.', backgroundColor: Colors.orange);
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

      _emailController.clear();
      if (mounted) {
        SnackbarHelper.show(context, 'Collaborator added successfully!', backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, 'Error adding collaborator: $e', backgroundColor: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _handleRoleChange(String userId, String newRole) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (newRole == 'remove') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(
                "Remove Access?",
                style: TextStyle(color: colorScheme.onSurface),
              ),
            ],
          ),
          content: Text(
            "This user will immediately lose all access to this pond's data.",
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.errorContainer,
                foregroundColor: colorScheme.onErrorContainer,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                _updateRole(userId, 'remove');
              },
              child: const Text("Remove"),
            ),
          ],
        ),
      );
    } else {
      _updateRole(userId, newRole);
    }
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
        await pondRef.update({
          'roles.$userId': newRole,
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, 'Failed to update role: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Share "${widget.pondName}"',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Column(
          children: [
            Container(
              color: colorScheme.surface,
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Enter user email...',
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isAdding ? null : _inviteCollaborator,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 20,
                      ),
                    ),
                    child: _isAdding
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Invite'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "People with access",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.onSurface,
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
                        style: TextStyle(color: colorScheme.error),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: roles.keys.length,
                    itemBuilder: (context, index) {
                      final userId = roles.keys.elementAt(index);
                      final role = roles[userId] as String;
                      final isMe = userId == currentUserId;

                      return CollaboratorTile(
                        userId: userId,
                        role: role,
                        isMe: isMe,
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
    );
  }
}

class CollaboratorTile extends StatefulWidget {
  final String userId;
  final String role;
  final bool isMe;
  final Function(String, String) onRoleChange;
  final Future<Map<String, dynamic>> Function(String) fetchUser;

  const CollaboratorTile({
    super.key,
    required this.userId,
    required this.role,
    required this.isMe,
    required this.onRoleChange,
    required this.fetchUser,
  });

  @override
  State<CollaboratorTile> createState() => _CollaboratorTileState();
}

class _CollaboratorTileState extends State<CollaboratorTile> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await widget.fetchUser(widget.userId);
    if (mounted) {
      setState(() {
        userData = data;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isLoading) {
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.dividerColor),
        ),
        child: const ListTile(
          leading: CircularProgressIndicator(),
          title: Text('Loading user...'),
        ),
      );
    }

    final name = userData?['fullName'] ?? 'Unknown User';
    final email = userData?['email'] ?? '';
    final initials = StringUtils.getInitials(name);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: widget.isMe
              ? colorScheme.primary
              : colorScheme.primaryContainer,
          child: Text(
            initials,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isMe
                  ? colorScheme.onPrimary
                  : colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          widget.isMe ? "$name (You)" : name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          email,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
        trailing: widget.isMe
            ? Tooltip(
                message: 'You cannot change your own role',
                triggerMode: TooltipTriggerMode.tap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.role.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.role,
                  icon: Icon(
                    Icons.expand_more,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  dropdownColor: colorScheme.surface,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'viewer',
                      child: Text('Viewer'),
                    ),
                    const DropdownMenuItem(
                      value: 'editor',
                      child: Text('Editor'),
                    ),
                    const DropdownMenuItem(
                      value: 'owner',
                      child: Text('Owner'),
                    ),
                    DropdownMenuItem(
                      value: 'remove',
                      child: Text(
                        'Remove access',
                        style: TextStyle(
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (newRole) {
                    if (newRole != null) {
                      widget.onRoleChange(widget.userId, newRole);
                    }
                  },
                ),
              ),
      ),
    );
  }
}