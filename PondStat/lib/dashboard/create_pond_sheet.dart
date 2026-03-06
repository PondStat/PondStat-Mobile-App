import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';

class CreatePondSheet extends StatefulWidget {
  const CreatePondSheet({super.key});

  @override
  State<CreatePondSheet> createState() => _CreatePondSheetState();
}

class _CreatePondSheetState extends State<CreatePondSheet> {
  final _formKey = GlobalKey<FormState>();

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

  void _createNewPond() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    final pondName = _newPondNameController.text.trim();
    final species = _speciesController.text.trim();

    final quantity = int.tryParse(_stockingQuantityController.text.trim()) ?? 0;
    final culturePeriod = int.tryParse(_culturePeriodController.text.trim()) ?? 0;
    final pondArea = double.tryParse(_pondAreaController.text.trim()) ?? 0.0;

    if (user == null) return;

    Navigator.of(context).pop();

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
  }
}