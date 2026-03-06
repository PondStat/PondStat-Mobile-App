import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'team_mgmt.dart';
import 'loading_overlay.dart'; 
import 'firestore_helper.dart'; // Import Helper

class LeaderDashboard extends StatefulWidget {
  const LeaderDashboard({super.key});

  @override
  State<LeaderDashboard> createState() => _LeaderDashboardState();
}

class _LeaderDashboardState extends State<LeaderDashboard> {
  String? selectedPanel;
  String? currentUserAssignedPond;
  String? userId;
  List<String> assignedPonds = [];
  bool isLoading = true;

  final List<String> panels = ['Pond 1', 'Pond 2', 'Pond 3'];

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _loadAssignedPonds();
  }

  Future<void> _loadAssignedPonds() async {
    if (userId == null) return;

    setState(() => isLoading = true);

    try {
      // [FIXED] Use FirestoreHelper
      final currentUserDoc =
          await FirestoreHelper.usersCollection.doc(userId).get();
      currentUserAssignedPond = currentUserDoc.data()?['assignedPond'] as String?;

      // [FIXED] Use FirestoreHelper
      final snapshot = await FirestoreHelper.usersCollection
          .where('role', isEqualTo: 'leader')
          .where('assignedPond', isNotEqualTo: null)
          .get();

      assignedPonds = snapshot.docs
          .map((doc) => doc.data()['assignedPond'])
          .whereType<String>()
          .where((pond) => pond != currentUserAssignedPond)
          .toList();

      if (currentUserAssignedPond != null) {
        selectedPanel = currentUserAssignedPond;
      }

      setState(() => isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ponds: $e')),
        );
      }
    }
  }

  Future<void> _confirmSelection() async {
    if (userId == null || selectedPanel == null) return;
    
    setState(() => isLoading = true);

    try {
      // [FIXED] Use FirestoreHelper
      final conflictingLeaders = await FirestoreHelper.usersCollection
          .where('role', isEqualTo: 'leader')
          .where('assignedPond', isEqualTo: selectedPanel)
          .where(FieldPath.documentId, isNotEqualTo: userId)
          .get();

      if (conflictingLeaders.docs.isNotEmpty) {
        throw Exception("This pond was just taken by another leader. Please refresh.");
      }

      // [FIXED] Use FirestoreHelper
      await FirestoreHelper.usersCollection
          .doc(userId)
          .update({'assignedPond': selectedPanel});

      currentUserAssignedPond = selectedPanel;

      if (mounted) {
        setState(() => isLoading = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamMgmt(
              selectedPanel: selectedPanel!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        _loadAssignedPonds(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select pond: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: LoadingOverlay(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            // Check if there is a screen to go back to (e.g., they opened this from the profile sheet)
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Safety Fallback: If this is the root screen because they haven't chosen a pond yet,
              // "going back" will safely sign them out instead of crashing or doing nothing.
              FirebaseAuth.instance.signOut();
            }
          },
        ),
        title: const Text('Leader Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignedPonds,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Your Pond',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...panels.map((panel) {
              final isAssigned = assignedPonds.contains(panel);
              final isSelected = selectedPanel == panel;

              return GestureDetector(
                onTap: isAssigned
                    ? null
                    : () {
                        setState(() => selectedPanel = panel);
                      },
                child: Card(
                  color: isSelected ? Colors.blue[100] : Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.water_drop,
                      color: isAssigned
                          ? Colors.grey
                          : isSelected
                              ? Colors.blue[700]
                              : Colors.grey[600],
                      size: 30,
                    ),
                    title: Text(
                      panel,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isAssigned
                            ? Colors.grey
                            : isSelected
                                ? Colors.blue[900]
                                : Colors.black87,
                      ),
                    ),
                    trailing: isAssigned
                        ? const Icon(Icons.lock, color: Colors.grey)
                        : isSelected
                            ? const Icon(Icons.check_circle, color: Colors.blue)
                            : const Icon(Icons.arrow_forward_ios, size: 18),
                  ),
                ),
              );
            }),
            const Spacer(),
            ElevatedButton(
              onPressed: selectedPanel == null ? null : _confirmSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}