import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/pondstat_dropdown_field.dart';
import 'package:pondstat/features/dashboard/data/dashboard_repository.dart';

class EditPondSheet extends StatefulWidget {
  final String pondId;
  final Map<String, dynamic> initialData;

  const EditPondSheet({
    super.key,
    required this.pondId,
    required this.initialData,
  });

  @override
  State<EditPondSheet> createState() => _EditPondSheetState();
}

class _EditPondSheetState extends State<EditPondSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late final TextEditingController _pondNameController;
  late final TextEditingController _stockingQuantityController;
  late final TextEditingController _culturePeriodController;

  String? _selectedSpecies;
  final List<String> _speciesOptions = ['Shrimp', 'Tilapia'];

  @override
  void initState() {
    super.initState();
    _pondNameController = TextEditingController(
      text: widget.initialData['name'] ?? '',
    );
    _stockingQuantityController = TextEditingController(
      text: widget.initialData['stockingQuantity']?.toString() ?? '',
    );
    _culturePeriodController = TextEditingController(
      text: widget.initialData['targetCulturePeriodDays']?.toString() ?? '',
    );

    final species = widget.initialData['species'];
    if (_speciesOptions.contains(species)) {
      _selectedSpecies = species;
    }
  }

  @override
  void dispose() {
    _pondNameController.dispose();
    _stockingQuantityController.dispose();
    _culturePeriodController.dispose();
    super.dispose();
  }

  Future<void> _updatePond() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final pondName = _pondNameController.text.trim();
    final species = _selectedSpecies ?? 'Unspecified';
    final quantity = int.tryParse(_stockingQuantityController.text.trim()) ?? 0;
    final culturePeriod =
        int.tryParse(_culturePeriodController.text.trim()) ?? 0;

    try {
      await DashboardRepository().updatePond(
        pondId: widget.pondId,
        name: pondName,
        species: species,
        stockingQuantity: quantity,
        targetCulturePeriodDays: culturePeriod,
      );

      if (mounted) {
        Navigator.of(context).pop();
        SnackbarHelper.show(
          context,
          'Pond updated successfully!',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      debugPrint("Background sync error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.show(
          context,
          'Failed to update pond: $e',
          backgroundColor: Colors.redAccent,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: isDark
              ? const Border(top: BorderSide(color: Colors.white12))
              : null,
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
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                _buildHeader(context, theme, isDark),
                const SizedBox(height: 32),

                PondStatTextField(
                  controller: _pondNameController,
                  label: 'Group Name',
                  hint: 'e.g., Group A',
                  prefixIcon: Icons.label_outline_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a group name'
                      : null,
                ),
                const SizedBox(height: 20),

                PondStatDropdownField<String>(
                  value: _selectedSpecies,
                  label: 'Target Species',
                  hint: 'Select species',
                  prefixIcon: Icons.set_meal_outlined,
                  items: _speciesOptions.map((String species) {
                    return DropdownMenuItem<String>(
                      value: species,
                      child: Text(species, overflow: TextOverflow.ellipsis),
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
                      child: PondStatTextField(
                        controller: _stockingQuantityController,
                        label: 'Quantity',
                        hint: '5000',
                        prefixIcon: Icons.numbers_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 16, top: 18),
                          child: Text(
                            'pcs',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
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
                        label: 'Culture Period',
                        hint: '90',
                        prefixIcon: Icons.calendar_month_rounded,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 16, top: 18),
                          child: Text(
                            'days',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
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
                const SizedBox(height: 36),

                PrimaryButton(
                  text: 'Save Changes',
                  icon: Icons.check_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? () {} : _updatePond,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            Icons.edit_rounded,
            color: theme.colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Pond Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update physical and biological parameters.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white12 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: isDark ? Colors.white54 : Colors.grey,
              size: 20,
            ),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}
