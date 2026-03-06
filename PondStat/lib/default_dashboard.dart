import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'no_pond_assigned.dart';
import 'profile_bottom_sheet.dart';
import 'getting_started_dialog.dart';
import 'leader_dashboard.dart';
import 'data_monitoring.dart'; 
import 'loading_overlay.dart';
import 'firestore_helper.dart'; // Import Helper

class DefaultDashboardScreen extends StatefulWidget {
  const DefaultDashboardScreen({super.key});

  @override
  State<DefaultDashboardScreen> createState() => _DefaultDashboardScreenState();
}

class _DefaultDashboardScreenState extends State<DefaultDashboardScreen> {
  // Tracks state for the ProfileBottomSheet
  bool _isTeamLeader = false; 

  @override
  void initState() {
    super.initState();
    _checkNewUser();
  }

  void _checkNewUser() async {
    // Logic handles the "No Pond" case.
  }

  void _showGettingStartedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const GettingStartedDialog(),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return ProfileBottomSheet(
          isTeamLeader: _isTeamLeader,
          assignedPond: null, 
          onRoleChanged: (isLeader) {
            setState(() => _isTeamLeader = isLeader);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not Authenticated")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreHelper.usersCollection.doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // 1. Loading State (waiting for connection)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingOverlay());
        }

        // 2. Error State
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }

        // 3. Handle Missing Document (Ghost User)
        if (!snapshot.hasData || !snapshot.data!.exists) {
           return Scaffold(
             body: Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.warning_amber_rounded, size: 50, color: Colors.orange),
                   const SizedBox(height: 20),
                   const Text("User profile not found.", style: TextStyle(fontSize: 18)),
                   const SizedBox(height: 10),
                   const Text(
                     "Your account exists but has no data.\nThis usually happens after a system update.",
                     textAlign: TextAlign.center,
                     style: TextStyle(color: Colors.grey),
                   ),
                   const SizedBox(height: 30),
                   ElevatedButton(
                     onPressed: () => FirebaseAuth.instance.signOut(),
                     child: const Text("Sign Out & Create New Account"),
                   ),
                 ],
               ),
             ),
           );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] ?? 'member';
        final assignedPond = data['assignedPond'];
        final String currentLeaderName = data['fullName'] ?? "Me";

        _isTeamLeader = (role == 'leader');

        // --- ROUTING LOGIC ---

        if (assignedPond != null) {
          if (role == 'leader') {
             // Let the leader go directly to their pond dashboard, 
             // regardless of whether they have 0 or 5 team members.
             return MonitoringPage(
                pondLetter: assignedPond,
                leaderName: currentLeaderName,
                isLeader: true,
              );
          } else {
            // For members, find out who their leader is to display on the dashboard
            return StreamBuilder<QuerySnapshot>(
              stream: FirestoreHelper.usersCollection
                  .where('assignedPond', isEqualTo: assignedPond)
                  .where('role', isEqualTo: 'leader')
                  .limit(1)
                  .snapshots(),
              builder: (context, leaderSnapshot) {
                if (leaderSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: LoadingOverlay());
                }

                String fetchedLeaderName = "Leader";
                if (leaderSnapshot.hasData && leaderSnapshot.data!.docs.isNotEmpty) {
                  fetchedLeaderName = leaderSnapshot.data!.docs.first['fullName'] ?? "Leader";
                }
                
                return MonitoringPage(
                  pondLetter: assignedPond,
                  leaderName: fetchedLeaderName,
                  isLeader: false,
                );
              },
            );
          }
        }

        // CASE 2: No Pond Assigned
        if (role == 'leader') {
          return const LeaderDashboard();
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGettingStartedDialog(context); 
        });

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            title: Row(
              children: [
                const Icon(Icons.water_drop, color: Colors.white, size: 28),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('PondStat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('Dashboard', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
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
          body: const NoPondAssignedWidget(),
        );
      },
    );
  }
}