import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../profile/profile_bottom_sheet.dart';
import '../firebase/firestore_helper.dart';
import 'create_pond_sheet.dart';
import 'pond_list_card.dart';
import '../getting_started_dialog.dart';

class DefaultDashboardScreen extends StatefulWidget {
  const DefaultDashboardScreen({super.key});

  @override
  State<DefaultDashboardScreen> createState() => _DefaultDashboardScreenState();
}

class _DefaultDashboardScreenState extends State<DefaultDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isFabVisible = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      GettingStartedDialog.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const ProfileBottomSheet(),
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
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_person_outlined,
                size: 72,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Session Expired",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please log in again to view your ponds.",
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.login),
                label: const Text("Log In"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.water_drop, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('My Ponds', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            tooltip: 'How it works',
            onPressed: () => GettingStartedDialog.showManual(context),
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.blue, size: 20),
            ),
            onPressed: () => _showProfileSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreHelper.pondsCollection
            .where('memberIds', arrayContains: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoader();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          var ponds = snapshot.data?.docs.toList() ?? [];

          if (ponds.isEmpty) {
            return _buildEmptyState(context);
          }

          return NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isFabVisible) setState(() => _isFabVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isFabVisible) setState(() => _isFabVisible = false);
              }
              return true;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16).copyWith(bottom: 80),
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
            ),
          );
        },
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _isFabVisible ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: () => _showCreatePondSheet(context),
            backgroundColor: Colors.blue,
            icon: const Icon(Icons.add),
            label: const Text(
              "New Pond",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity:
              Tween<double>(begin: 0.4, end: 1.0).animate(_shimmerController),
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 20, width: 150, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Container(height: 14, width: 100, color: Colors.grey.shade200),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 24,
                      width: 80,
                      color: Colors.grey.shade200,
                    ),
                    Container(
                      height: 24,
                      width: 24,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              "No Ponds Yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Start tracking your aquaculture farm by creating your first pond.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreatePondSheet(context),
              icon: const Icon(Icons.add),
              label: const Text("Create First Pond"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                "Something went wrong",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}