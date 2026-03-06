import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../no_pond_assigned.dart';
import '../profile_bottom_sheet.dart';
import '../loading_overlay.dart';
import '../firebase/firestore_helper.dart';
import 'create_pond_sheet.dart';
import 'pond_list_card.dart';

class DefaultDashboardScreen extends StatelessWidget {
  const DefaultDashboardScreen({super.key});

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ProfileBottomSheet(
          isTeamLeader: false,
          assignedPond: null,
          onRoleChanged: (isLeader) {},
        );
      },
    );
  }

  void _showCreatePondSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreatePondSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Authenticated")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.water_drop, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('My Ponds', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue),
            ),
            onPressed: () => _showProfileSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.pondsCollection
            .where('memberIds', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingOverlay();
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Database Error:\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          var ponds = snapshot.data?.docs.toList() ?? [];

          if (ponds.isEmpty) {
            return const NoPondAssignedWidget();
          }

          ponds.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.fromMillisecondsSinceEpoch(0);

            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ponds.length,
            itemBuilder: (context, index) {
              final pondDoc = ponds[index];
              final pondData = pondDoc.data() as Map<String, dynamic>;

              return PondListCard(
                pondId: pondDoc.id,
                pondName: pondData['name'] ?? 'Unnamed Pond',
                species: pondData['species'] ?? 'Unspecified',
                userRole: pondData['roles']?[user.uid] ?? 'viewer',
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePondSheet(context),
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("New Pond"),
      ),
    );
  }
}