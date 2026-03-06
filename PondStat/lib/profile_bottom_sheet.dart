import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leader_dashboard.dart';
import 'team_mgmt.dart';
import 'firestore_helper.dart'; // Import Helper

class ProfileBottomSheet extends StatefulWidget {
  final bool isTeamLeader;
  final String? assignedPond;
  final Function(bool) onRoleChanged;

  const ProfileBottomSheet({
    super.key,
    required this.isTeamLeader,
    this.assignedPond,
    required this.onRoleChanged,
  });

  @override
  State<ProfileBottomSheet> createState() => _ProfileBottomSheetState();
}

class _ProfileBottomSheetState extends State<ProfileBottomSheet> {
  late bool _currentIsLeader;
  bool _isUpdating = false;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _currentIsLeader = widget.isTeamLeader;
  }

  Future<void> _updateTeamRole(bool isLeader) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final userRef = FirestoreHelper.usersCollection.doc(user.uid);

    try {
      final batch = firestore.batch();

      if (!isLeader) {
        final userDoc = await userRef.get();
        final String? currentPond = userDoc.data()?['assignedPond'];

        if (currentPond != null) {
          final teamMembersSnapshot = await FirestoreHelper.usersCollection
              .where('assignedPond', isEqualTo: currentPond)
              .where('role', isEqualTo: 'member')
              .get();

          for (var doc in teamMembersSnapshot.docs) {
            batch.update(doc.reference, {'assignedPond': null});
          }
        }
      }

      batch.update(userRef, {
        'role': isLeader ? 'leader' : 'member',
        'assignedPond': isLeader ? null : FieldValue.delete(),
      });

      await batch.commit();
      print('✅ Role updated successfully: $isLeader');
    } catch (e) {
      print('❌ Failed to update role: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 224, 224, 224),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          _buildUserInfo(),
          const SizedBox(height: 16),
          _buildTeamRoleCard(),
          const SizedBox(height: 16),
          
          _buildMenuButton(
            icon: Icons.edit_outlined,
            text: 'Edit Profile',
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfilePage()),
              );
            },
          ),
          
          _buildMenuButton(
            icon: Icons.group_outlined,
            text: 'My Team',
            onTap: () {
              Navigator.pop(context);

              if (_currentIsLeader) {
                if (widget.assignedPond != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamMgmt(
                        selectedPanel: widget.assignedPond!,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please select a pond from the dashboard to manage your team.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please contact your team leader to be assigned to a pond.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          _buildMenuButton(
            icon: Icons.logout,
            text: 'Sign Out',
            isSignOut: true,
            onTap: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color.fromARGB(255, 33, 130, 243),
          child: const Icon(
            Icons.person,
            size: 30,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user?.displayName ?? 'User Name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'No Email',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamRoleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Role',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor:
                  _currentIsLeader ? Theme.of(context).primaryColor : Colors.grey,
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              _currentIsLeader ? 'Team Leader' : 'Team Member',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _currentIsLeader ? 'Manage pond & members' : 'Contribute to team',
            ),
            trailing: _isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: _currentIsLeader,
                    onChanged: (newValue) async {
                      bool confirm = true;
                      if (_currentIsLeader && !newValue) {
                         confirm = await showDialog(
                           context: context, 
                           builder: (ctx) => AlertDialog(
                             title: const Text("Change Role?"),
                             content: const Text("Switching to 'Member' will release your current pond and remove all assigned members from your team."),
                             actions: [
                               TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                               TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Confirm")),
                             ],
                           )
                         ) ?? false;
                      }

                      if (!confirm) return;

                      setState(() {
                        _currentIsLeader = newValue;
                        _isUpdating = true;
                      });

                      try {
                        await _updateTeamRole(newValue);
                        if (mounted) {
                          widget.onRoleChanged(newValue);
                          setState(() => _isUpdating = false);
                        }
                      } catch (e) {
                        if (mounted) {
                          setState(() {
                            _currentIsLeader = !newValue;
                            _isUpdating = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Failed to update role')),
                          );
                        }
                      }
                    },
                    activeThumbColor: Theme.of(context).primaryColor,
                  ),
          ),
          if (_currentIsLeader) ...[
            const SizedBox(height: 12),
            _buildLeaderInfoBox(
              'As a leader, you can now access the leader dashboard.',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LeaderDashboard()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Go to Leader Dashboard'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderInfoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFB3E5FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0277BD)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF01579B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    bool isSignOut = false,
    required VoidCallback onTap,
  }) {
    final Color textColor = isSignOut ? Colors.red[700]! : Colors.black87;
    final Color bgColor = isSignOut ? Colors.white : Colors.grey[100]!;
    final Color? borderColor = isSignOut ? Colors.red[300] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: textColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: borderColor != null
                  ? BorderSide(color: borderColor)
                  : BorderSide.none,
            ),
            elevation: 0,
            alignment: Alignment.centerLeft,
          ),
          child: Row(
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _studentNumController = TextEditingController();

  bool _isLoading = false;
  
  String _initialName = '';
  String _initialStudentNum = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
        print("Error fetching user data: $e");
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      bool nameChanged = _nameController.text.trim() != _initialName;
      bool studentNumChanged = _studentNumController.text.trim() != _initialStudentNum;

      if (nameChanged) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      final Map<String, dynamic> firestoreUpdates = {};
      if (nameChanged) firestoreUpdates['fullName'] = _nameController.text.trim();
      if (studentNumChanged) firestoreUpdates['studentNumber'] = _studentNumController.text.trim();

      if (firestoreUpdates.isNotEmpty) {
        await FirestoreHelper.usersCollection.doc(user.uid).update(firestoreUpdates);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context); // Go back
      }

    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color customBlue = Color(0xFF0077C2);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        backgroundColor: customBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Public Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _studentNumController,
                decoration: const InputDecoration(
                  labelText: "Student Number",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: customBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}