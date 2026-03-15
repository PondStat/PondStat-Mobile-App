import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentNumController = TextEditingController();

  bool _isFetching = true;
  bool _isLoading = false;

  String _initialName = '';
  String _initialStudentNum = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentNumController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _initialName = user.displayName ?? '';

      try {
        final doc = await FirestoreHelper.usersCollection.doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final sNum = data['studentNumber']?.toString() ?? '';

          _studentNumController.text = sNum;
          _initialStudentNum = sNum;

          if (data.containsKey('fullName')) {
            final fName = data['fullName']?.toString() ?? '';
            _nameController.text = fName;
            _initialName = fName;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }

    if (mounted) {
      setState(() => _isFetching = false);
    }
  }

  bool _hasUnsavedChanges() {
    return _nameController.text.trim() != _initialName ||
        _studentNumController.text.trim() != _initialStudentNum;
  }

  Future<void> _showDiscardDialog() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Discard changes?",
          style: TextStyle(color: colorScheme.onSurface),
        ),
        content: Text(
          "You have unsaved changes. Are you sure you want to leave without saving?",
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Keep Editing",
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Discard"),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      bool nameChanged = _nameController.text.trim() != _initialName;
      bool studentNumChanged =
          _studentNumController.text.trim() != _initialStudentNum;

      if (nameChanged) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      final Map<String, dynamic> firestoreUpdates = {};
      if (nameChanged) {
        firestoreUpdates['fullName'] = _nameController.text.trim();
      }
      if (studentNumChanged) {
        firestoreUpdates['studentNumber'] = _studentNumController.text.trim();
      }

      if (firestoreUpdates.isNotEmpty) {
        await FirestoreHelper.usersCollection
            .doc(user.uid)
            .update(firestoreUpdates);
      }

      if (mounted) {
        setState(() {
          _initialName = _nameController.text.trim();
          _initialStudentNum = _studentNumController.text.trim();
        });

        SnackbarHelper.show(context, 'Profile updated successfully!', backgroundColor: Colors.green);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Failed to update profile: $e", backgroundColor: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;
          if (_hasUnsavedChanges() && !_isLoading) {
            await _showDiscardDialog();
          } else {
            Navigator.pop(context);
          }
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: _isFetching
              ? const Center(child: CircularProgressIndicator())
              : _buildFormContent(),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoUrl = currentUser?.photoURL;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (currentUser?.displayName ?? 'Unknown');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null
                        ? Text(
                            StringUtils.getInitials(displayName),
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          )
                        : null,
                  ),
                  GestureDetector(
                    onTap: () {
                      SnackbarHelper.show(context, 'Profile picture uploads coming soon!');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Public Info",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              enabled: !_isLoading,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? "Name is required" : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _studentNumController,
              enabled: !_isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) {
                if (_hasUnsavedChanges() && !_isLoading) {
                  _saveChanges();
                }
              },
              decoration: const InputDecoration(
                labelText: "Student Number",
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: (val) => val == null || val.trim().isEmpty
                  ? "Student number is required"
                  : null,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: (_isLoading || !_hasUnsavedChanges())
                  ? null
                  : _saveChanges,
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}