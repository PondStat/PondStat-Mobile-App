import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';
import '../widgets/primary_button.dart';
import '../widgets/pondstat_text_field.dart';

class CreatePondSheet extends StatefulWidget {
  const CreatePondSheet({super.key});

  @override
  State<CreatePondSheet> createState() => _CreatePondSheetState();
}

class _CreatePondSheetState extends State<CreatePondSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final TextEditingController _newPondNameController = TextEditingController();
  final TextEditingController _stockingQuantityController =
      TextEditingController();
  final TextEditingController _culturePeriodController =
      TextEditingController();
  final TextEditingController _pondAreaController = TextEditingController();

  String? _selectedSpecies;
  final List<String> _speciesOptions = ['Shrimp', 'Tilapia'];

  @override
  void dispose() {
    _newPondNameController.dispose();
    _stockingQuantityController.dispose();
    _culturePeriodController.dispose();
    _pondAreaController.dispose();
    super.dispose();
  }

  void _createNewPond() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final pondName = _newPondNameController.text.trim();
    final species = _selectedSpecies ?? 'Unspecified';
    final quantity = int.tryParse(_stockingQuantityController.text.trim()) ?? 0;
    final culturePeriod =
        int.tryParse(_culturePeriodController.text.trim()) ?? 0;
    final pondArea = double.tryParse(_pondAreaController.text.trim()) ?? 0.0;

    try {
      final newPondRef = FirestoreHelper.pondsCollection.doc();

      newPondRef
          .set({
            'name': pondName,
            'species': species,
            'stockingQuantity': quantity,
            'targetCulturePeriodDays': culturePeriod,
            'pondAreaSqm': pondArea,
            'createdAt': FieldValue.serverTimestamp(),
            'ownerId': user.uid,
            'memberIds': [user.uid],
            'roles': {user.uid: 'owner'},
          })
          .catchError((error) {
            debugPrint("Background sync error: $error");
          });

      if (mounted) {
        Navigator.of(context).pop();
        SnackbarHelper.show(
          context,
          'Pond setup complete!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.show(
          context,
          'Failed to create pond: $e',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
          top: 12,
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
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _buildHeader(context),
                const SizedBox(height: 32),

                PondStatTextField(
                  controller: _newPondNameController,
                  label: 'Pond Name *',
                  hint: 'e.g., North Farm',
                  prefixIcon: Icons.label_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'TARGET SPECIES *',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecies,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey.shade600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Select species',
                        prefixIcon: Icon(Icons.set_meal_outlined, size: 20),
                      ),
                      items: _speciesOptions.map((String species) {
                        return DropdownMenuItem<String>(
                          value: species,
                          child: Text(
                            species,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _isLoading
                          ? null
                          : (val) => setState(() => _selectedSpecies = val),
                      validator: (value) =>
                          value == null ? 'Select a species' : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PondStatTextField(
                        controller: _stockingQuantityController,
                        label: 'Quantity',
                        hint: '50000',
                        prefixIcon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 16, top: 18),
                          child: Text(
                            'pcs',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if ((int.tryParse(val) ?? 0) <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PondStatTextField(
                        controller: _culturePeriodController,
                        label: 'Period',
                        hint: '120',
                        prefixIcon: Icons.calendar_month_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 16, top: 18),
                          child: Text(
                            'days',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Required';
                          if ((int.tryParse(val) ?? 0) <= 0) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                PondStatTextField(
                  controller: _pondAreaController,
                  label: 'Pond Area',
                  hint: '2500',
                  prefixIcon: Icons.square_foot_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.done,
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16, top: 18),
                    child: Text(
                      'sqm',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if ((double.tryParse(val) ?? 0) <= 0) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                PrimaryButton(
                  text: 'Create Pond',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _createNewPond,
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.water_drop_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Up a New Pond',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Enter the physical and biological parameters.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
