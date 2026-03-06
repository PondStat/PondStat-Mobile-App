import 'dart:ui';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'default_dashboard.dart';
import 'firestore_helper.dart'; // Import Helper

class TeamMgmt extends StatefulWidget {
  final String selectedPanel;

  const TeamMgmt({super.key, required this.selectedPanel});

  @override
  State<TeamMgmt> createState() => _TeamMgmtState();
}

class _TeamMgmtState extends State<TeamMgmt> {
  final TextEditingController _searchController = TextEditingController();
  final String? _currentLeaderName =
      FirebaseAuth.instance.currentUser?.displayName;

  List<DocumentSnapshot> _allUsers = [];
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllUsers() async {
    try {
      // [FIXED] Use FirestoreHelper
      // Removed .where() to satisfy strict security rules if needed, 
      // but with updated rules, this works. Using pure fetch is safest.
      final snapshot = await FirestoreHelper.usersCollection.get();

      if (mounted) {
        setState(() {
          // Filter in memory for safety
          _allUsers = snapshot.docs.where((doc) {
             final data = doc.data();
             return data['role'] == 'member';
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching users: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = _allUsers.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final name = (data['fullName'] ?? '').toString().toLowerCase();
        final currentPond = data['assignedPond'];

        bool matchesSearch = name.contains(query);
        bool notInTeam = currentPond != widget.selectedPanel;

        return matchesSearch && notInTeam;
      }).toList();
    });
  }

  Future<void> _addMember(DocumentSnapshot oldUserDoc) async {
    final DocumentSnapshot userDoc;
    try {
      // [FIXED] Use FirestoreHelper
      userDoc = await FirestoreHelper.usersCollection
          .doc(oldUserDoc.id)
          .get();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to refresh user data.')));
      return;
    }

    final userData = userDoc.data() as Map<String, dynamic>;
    final String currentPond = userData['assignedPond'] ?? '';
    final String name = userData['fullName'] ?? 'Student';

    if (currentPond.isNotEmpty && currentPond != widget.selectedPanel) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name is already in $currentPond. Remove them first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() {
        _searchResults.removeWhere((doc) => doc.id == userDoc.id);
      });

      // [FIXED] Use FirestoreHelper
      await FirestoreHelper.usersCollection
          .doc(userDoc.id)
          .update({'assignedPond': widget.selectedPanel});

      _fetchAllUsers(); // Refresh list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$name added to team!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        _onSearchChanged(); 
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _removeMember(String uid) async {
    try {
      // [FIXED] Use FirestoreHelper
      await FirestoreHelper.usersCollection
          .doc(uid)
          .update({'assignedPond': null});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed')),
      );
      
      _fetchAllUsers();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color customBlue = Color(0xFF0077C2);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: customBlue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(Icons.waves, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Add Team Members",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${widget.selectedPanel} - ${_currentLeaderName ?? 'My'} Team",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "  Manage Team",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: customBlue,
                          ),
                        ),
                        const SizedBox(height: 8),

                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: "Search by name or student number...",
                            prefixIcon:
                                const Icon(Icons.search, color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: customBlue),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Expanded(
                          child: _isSearching
                              ? _buildSearchResults()
                              : _buildDashboard(),
                        ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const AuthWrapper()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(
        child: Text("No students found", style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final doc = _searchResults[index];
        return _buildUserCard(doc, isSearchResult: true);
      },
    );
  }

  Widget _buildDashboard() {
    final availableMembers = _allUsers.where((doc) {
       final data = doc.data() as Map<String, dynamic>;
       return data['assignedPond'] == null;
    }).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentTeamList(),
          const Divider(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                 const Icon(Icons.person_add_alt_1_outlined, color: Colors.grey),
                 const SizedBox(width: 8),
                 Text(
                   "Available Students (${availableMembers.length})",
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                 ),
              ],
            ),
          ),
          if (availableMembers.isEmpty)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Center(child: Text("No unassigned students found.\nUse Sign Up to create member accounts.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12))),
             )
          else
            ...availableMembers.map((doc) => _buildUserCard(doc, isSearchResult: true)).toList(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUserCard(DocumentSnapshot doc, {required bool isSearchResult}) {
      final data = doc.data() as Map<String, dynamic>;
      final isAssignedOther = (data['assignedPond'] != null);
      
      return Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person, color: Colors.grey),
          ),
          title: Text(
            data['fullName'] ?? 'Unknown',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14),
          ),
          subtitle: Text(
            "In ${data['assignedPond']}",
            style: TextStyle(
              color: isAssignedOther ? Colors.orange : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          trailing: isSearchResult 
            ? InkWell(
                onTap: () => _addMember(doc),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(50), 
                  ),
                  child: const Icon(Icons.person_add,
                      color: Color(0xFF0077C2), size: 20),
                ),
              )
            : IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _removeMember(doc.id),
              ),
        ),
      );
  }

  Widget _buildCurrentTeamList() {
    return StreamBuilder<QuerySnapshot>(
      // [FIXED] Use FirestoreHelper
      stream: FirestoreHelper.usersCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        
        // Filter in memory
        final members = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['assignedPond'] == widget.selectedPanel;
        }).toList();

        final int memberCount = members.length;

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.group_outlined, color: Color(0xFF0077C2)),
                    SizedBox(width: 8),
                    Text(
                      "Current Team",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077C2),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    "$memberCount",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (memberCount == 0)
               Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.group_add, size: 32, color: Colors.grey),
                        SizedBox(height: 8),
                        Text("No team members yet", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
            else
              Column(
                children: members.map((m) => _buildUserCard(m, isSearchResult: false)).toList(),
              ),
          ],
        );
      },
    );
  }
}