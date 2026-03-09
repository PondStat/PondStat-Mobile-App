import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLoading = false;

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

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final pondName = _newPondNameController.text.trim();
    final species = _speciesController.text.trim();
    final quantity = int.tryParse(_stockingQuantityController.text.trim()) ?? 0;
    final culturePeriod = int.tryParse(_culturePeriodController.text.trim()) ?? 0;
    final pondArea = double.tryParse(_pondAreaController.text.trim()) ?? 0.0;

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
        'roles': {user.uid: 'owner'},
      });

      if (mounted) {
        Navigator.of(context).pop();
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
        setState(() => _isLoading = false);
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
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
                _buildHeader(context),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _newPondNameController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter a name'
                          : null,
                  decoration: const InputDecoration(
                    labelText: 'Pond Name *',
                    hintText: 'e.g., North Farm',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _speciesController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Target Species',
                    hintText: 'e.g., Tilapia',
                    prefixIcon: Icon(Icons.set_meal_outlined),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockingQuantityController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Qty (pcs)',
                          hintText: '50000',
                          prefixIcon: Icon(Icons.numbers),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _culturePeriodController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Days',
                          hintText: '120',
                          prefixIcon: Icon(Icons.calendar_month),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _pondAreaController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Pond Area (sqm)',
                    hintText: '2500',
                    prefixIcon: Icon(Icons.square_foot),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _createNewPond,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Create Pond'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.water_drop,
            color: Theme.of(context).primaryColor,
            size: 28,
          ),
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
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }
}