import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'no_pond_assigned.dart';
import 'profile_bottom_sheet.dart';
import 'loading_overlay.dart';
import 'firestore_helper.dart';
import 'data_monitoring.dart'; 

class DefaultDashboardScreen extends StatefulWidget {
  const DefaultDashboardScreen({super.key});

  @override
  State<DefaultDashboardScreen> createState() => _DefaultDashboardScreenState();
}

class _DefaultDashboardScreenState extends State<DefaultDashboardScreen> {
  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _newPondNameController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _stockingQuantityController = TextEditingController();
  final TextEditingController _culturePeriodController = TextEditingController();
  final TextEditingController _pondAreaController = TextEditingController(); 

  @override
  void dispose() {
    _newPondNameController.dispose();
    _speciesController.dispose();
    _stockingQuantityController.dispose();
    _culturePeriodController.dispose();
    _pondAreaController.dispose();
    super.dispose();
  }

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

  // --- Dynamic Expanded Pond Creation ---
  void _createNewPond() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    final user = FirebaseAuth.instance.currentUser;
    final pondName = _newPondNameController.text.trim();
    final species = _speciesController.text.trim();
    
    // Parse numeric values safely, defaulting to 0 if left blank
    final quantity = int.tryParse(_stockingQuantityController.text.trim()) ?? 0;
    final culturePeriod = int.tryParse(_culturePeriodController.text.trim()) ?? 0;
    final pondArea = double.tryParse(_pondAreaController.text.trim()) ?? 0.0;
    
    if (user == null) return;

    Navigator.of(context).pop(); // Close the sheet
    
    // Clear the form for the next time it's opened
    _newPondNameController.clear();
    _speciesController.clear();
    _stockingQuantityController.clear();
    _culturePeriodController.clear();
    _pondAreaController.clear();

    try {
      await FirestoreHelper.pondsCollection.add({
        'name': pondName,
        'species': species.isNotEmpty ? species : 'Unspecified',
        'stockingQuantity': quantity,
        'targetCulturePeriodDays': culturePeriod,
        'pondAreaSqm': pondArea,
        'createdAt': FieldValue.serverTimestamp(),
        'ownerId': user.uid,
        'memberIds': [user.uid], 
        'roles': {
          user.uid: 'owner', 
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pond setup complete!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create pond: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- NEW POLISHED UX/UI: Bottom Sheet ---
  void _showCreatePondSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Allows for custom rounded corners
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          // Padding adjusts dynamically when the keyboard pops up
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Beautiful Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.water_drop, color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Set Up a New Pond',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Fields with modern styling
                  TextFormField(
                    controller: _newPondNameController,
                    validator: (value) => value == null || value.trim().isEmpty 
                        ? 'Please enter a pond name' 
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Pond Name *',
                      hintText: 'e.g., North Farm Pond',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _speciesController,
                    decoration: InputDecoration(
                      labelText: 'Target Species',
                      hintText: 'e.g., Whiteleg Shrimp, Tilapia',
                      prefixIcon: const Icon(Icons.set_meal_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _stockingQuantityController,
                          decoration: InputDecoration(
                            labelText: 'Quantity (pcs)',
                            hintText: 'e.g., 50000',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _culturePeriodController,
                          decoration: InputDecoration(
                            labelText: 'Period (Days)',
                            hintText: 'e.g., 120',
                            prefixIcon: const Icon(Icons.calendar_month_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _pondAreaController,
                    decoration: InputDecoration(
                      labelText: 'Pond Area (sqm)',
                      hintText: 'e.g., 2500',
                      prefixIcon: const Icon(Icons.square_foot),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 32),

                  // Full-width prominent CTA button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    onPressed: _createNewPond,
                    child: const Text(
                      'Create Pond',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            
            final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            
            return bTime.compareTo(aTime); 
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ponds.length,
            itemBuilder: (context, index) {
              final pondDoc = ponds[index];
              final pondData = pondDoc.data() as Map<String, dynamic>;
              
              final pondName = pondData['name'] ?? 'Unnamed Pond';
              final species = pondData['species'] ?? 'Unspecified';
              final userRole = pondData['roles']?[user.uid] ?? 'viewer';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: const Icon(Icons.water, color: Colors.blue),
                  ),
                  title: Text(pondName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Species: $species',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${userRole.toString().toUpperCase()}', 
                          style: TextStyle(
                            color: userRole == 'owner' ? Colors.green[700] : Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context, 
                      MaterialPageRoute(
                        builder: (_) => MonitoringPage(
                          pondId: pondDoc.id, 
                          pondName: pondName,
                          userRole: userRole,
                        )
                      )
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePondSheet, // <-- Updated to call the new Sheet!
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text("New Pond"),
      ),
    );
  }
}