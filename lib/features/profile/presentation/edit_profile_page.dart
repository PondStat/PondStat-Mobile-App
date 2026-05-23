import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/utils/string_extensions.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';
import 'package:pondstat/features/auth/data/auth_repository.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentNumController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _studentNumFocus = FocusNode();

  final ValueNotifier<bool> _hasChanges = ValueNotifier(false);

  bool _isFetching = true;
  bool _isLoading = false;

  String _initialName = '';
  String _initialStudentNum = '';

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;
  Color get backgroundLight => Theme.of(context).scaffoldBackgroundColor;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _nameController.addListener(_checkForChanges);
    _studentNumController.addListener(_checkForChanges);

    _nameFocus.addListener(() => setState(() {}));
    _studentNumFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentNumController.dispose();
    _nameFocus.dispose();
    _studentNumFocus.dispose();
    _hasChanges.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanged =
        _nameController.text.trim() != _initialName ||
        _studentNumController.text.trim() != _initialStudentNum;

    if (_hasChanges.value != hasChanged) {
      _hasChanges.value = hasChanged;
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _initialName = user.displayName ?? '';

      try {
        final doc = await ref.read(authRepositoryProvider).usersCollection.doc(user.uid).get();
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
      } catch (e, stackTrace) {
        ref.read(appLoggerProvider).error("Error fetching user data", error: e, stackTrace: stackTrace, tag: 'PROFILE');
      }
    }

    if (mounted) {
      setState(() => _isFetching = false);
      _checkForChanges();
    }
  }

  Future<void> _handleBackNavigation() async {
    if (_hasChanges.value && !_isLoading) {
      await _showDiscardDialog();
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _showDiscardDialog() async {
    HapticFeedback.selectionClick();
    final shouldDiscard = await showDialog<bool>(
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
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            Text(
              "Discard changes?",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          "You have unsaved changes. Are you sure you want to leave without saving?",
          style: TextStyle(color: textMuted, height: 1.4, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Keep Editing",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade900,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Discard",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (shouldDiscard == true && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _saveChanges() async {
    FocusScope.of(context).unfocus();

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
        await ref.read(authRepositoryProvider).usersCollection
            .doc(user.uid)
            .update(firestoreUpdates);
      }

      if (mounted) {
        setState(() {
          _initialName = _nameController.text.trim();
          _initialStudentNum = _studentNumController.text.trim();
        });

        _checkForChanges();
        HapticFeedback.heavyImpact();

        SnackbarHelper.showInfo(context, 'Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Failed to update profile: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          await _handleBackNavigation();
        },
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        onPressed: _handleBackNavigation,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Edit Profile",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _isFetching
                        ? Center(
                            key: const ValueKey('loading'),
                            child: CircularProgressIndicator(
                              color: primaryBlue,
                            ),
                          )
                        : KeyedSubtree(
                            key: const ValueKey('form'),
                            child: _buildFormContent(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final photoUrl = currentUser?.photoURL;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : (currentUser?.displayName ?? 'Unknown');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryBlue.withValues(alpha: 0.15),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue.shade50,
                            child: photoUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return CircularProgressIndicator(
                                              color: primaryBlue,
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Text(
                                              displayName.initials,
                                              style: TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.w900,
                                                color: primaryBlue,
                                              ),
                                            );
                                          },
                                    ),
                                  )
                                : Text(
                                    displayName.initials,
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      color: primaryBlue,
                                    ),
                                  ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            SnackbarHelper.showInfo(context, 'Profile picture uploads coming soon!',);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [secondaryBlue, primaryBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryBlue.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  Text(
                    "PUBLIC INFO",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: primaryBlue,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  PondStatTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    label: "Full Name",
                    prefixIcon: Icons.person_outline_rounded,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    enabled: !_isLoading,
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Name is required"
                        : null,
                  ),
                  const SizedBox(height: 24),

                  PondStatTextField(
                    controller: _studentNumController,
                    focusNode: _studentNumFocus,
                    label: "Student Number",
                    prefixIcon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    enabled: !_isLoading,
                    onSubmitted: (_) {
                      if (_hasChanges.value && !_isLoading) _saveChanges();
                    },
                    validator: (val) => val == null || val.trim().isEmpty
                        ? "Student number is required"
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),

        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: backgroundLight,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundLight.withValues(alpha: 0.0),
                backgroundLight,
                backgroundLight,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: ValueListenableBuilder<bool>(
            valueListenable: _hasChanges,
            builder: (context, hasChanges, child) {
              return PrimaryButton(
                text: "Save Changes",
                onPressed: (_isLoading || !hasChanges) ? null : _saveChanges,
                isLoading: _isLoading,
                backgroundColor: primaryBlue,
              );
            },
          ),
        ),
      ],
    );
  }
}
