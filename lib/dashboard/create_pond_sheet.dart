import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';

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
  final List<String> _speciesOptions = [
    'Culture of shrimp',
    'UPV SpiN tilapia',
  ];

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

  InputDecoration _buildInputDecoration(
    BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    final primaryColor = Theme.of(context).primaryColor;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.grey.shade50,
      labelStyle: TextStyle(
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w500,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade400),
      suffixStyle: TextStyle(
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
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

                TextFormField(
                  controller: _newPondNameController,
                  enabled: !_isLoading,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Pond Name *',
                    hint: 'e.g., North Farm',
                    icon: Icons.label_outline_rounded,
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  isExpanded: true,
                  icon: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Target Species *',
                    hint: 'Select species',
                    icon: Icons.set_meal_outlined,
                  ),
                  items: _speciesOptions.map((String species) {
                    return DropdownMenuItem<String>(
                      value: species,
                      child: Text(
                        species,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
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
                const SizedBox(height: 20),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockingQuantityController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _buildInputDecoration(
                          context,
                          label: 'Quantity',
                          hint: '50000',
                          icon: Icons.numbers_rounded,
                          suffixText: 'pcs',
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
                      child: TextFormField(
                        controller: _culturePeriodController,
                        enabled: !_isLoading,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _buildInputDecoration(
                          context,
                          label: 'Period',
                          hint: '120',
                          icon: Icons.calendar_month_rounded,
                          suffixText: 'days',
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

                TextFormField(
                  controller: _pondAreaController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: _buildInputDecoration(
                    context,
                    label: 'Pond Area',
                    hint: '2500',
                    icon: Icons.square_foot_rounded,
                    suffixText: 'sqm',
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Required';
                    if ((double.tryParse(val) ?? 0) <= 0) return 'Invalid';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createNewPond,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Create Pond',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
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
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.2),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.water_drop_rounded,
            color: Theme.of(context).primaryColor,
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
