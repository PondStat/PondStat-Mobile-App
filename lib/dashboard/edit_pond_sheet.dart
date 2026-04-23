import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firestore_helper.dart';
import '../utility/helpers.dart';
import '../widgets/primary_button.dart';
import '../widgets/pondstat_text_field.dart';

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
  bool _isSuccess = false;

  late final TextEditingController _pondNameController;
  late final TextEditingController _stockingQuantityController;
  late final TextEditingController _culturePeriodController;

  String? _selectedSpecies;
  final List<String> _speciesOptions = ['Shrimp', 'Tilapia'];

  bool get _isFormValid =>
      _pondNameController.text.trim().isNotEmpty &&
      _selectedSpecies != null &&
      int.tryParse(_stockingQuantityController.text.trim()) != null &&
      int.tryParse(_culturePeriodController.text.trim()) != null;

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

    _pondNameController.addListener(() => setState(() {}));
    _stockingQuantityController.addListener(() => setState(() {}));
    _culturePeriodController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pondNameController.dispose();
    _stockingQuantityController.dispose();
    _culturePeriodController.dispose();
    super.dispose();
  }

  Future<void> _updatePond() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

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
      final pondRef = FirestoreHelper.pondsCollection.doc(widget.pondId);

      await pondRef.update({
        'name': pondName,
        'species': species,
        'stockingQuantity': quantity,
        'targetCulturePeriodDays': culturePeriod,
      });

      if (mounted) {
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          Navigator.of(context).pop();
          SnackbarHelper.show(
            context,
            'Pond updated successfully!',
            backgroundColor: Colors.green,
          );
        }
      }
    } catch (e) {
      debugPrint("Background sync error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.show(
          context,
          'Something went wrong. Please try again.',
          backgroundColor: Colors.redAccent,
          actionLabel: 'Retry',
          onAction: _updatePond,
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSpeciesCard(
    String species,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _selectedSpecies == species;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _isLoading
          ? null
          : () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedSpecies = species;
                if (species == 'Shrimp' &&
                    _culturePeriodController.text.isEmpty) {
                  _culturePeriodController.text = '90';
                } else if (species == 'Tilapia' &&
                    _culturePeriodController.text.isEmpty) {
                  _culturePeriodController.text = '120';
                }
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.1)
              : (isDark ? Colors.white12 : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                key: ValueKey(isSelected),
                color: isSelected
                    ? colorScheme.primary
                    : (isDark ? Colors.white54 : Colors.grey),
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'Inter',
                color: isSelected
                    ? colorScheme.primary
                    : (isDark ? Colors.white70 : Colors.grey.shade700),
              ),
              child: Text(species),
            ),
          ],
        ),
      ),
    );
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
          child: IgnorePointer(
            ignoring: _isLoading || _isSuccess,
            child: AnimatedOpacity(
              opacity: (_isLoading || _isSuccess) ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 300),
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
                    const SizedBox(height: 24),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade100,
                    ),
                    const SizedBox(height: 24),

                    _buildSectionHeader('Basic Information', theme),
                    PondStatTextField(
                      controller: _pondNameController,
                      label: 'Pond Name',
                      hint: 'e.g., Pond A',
                      prefixIcon: Icons.label_outline_rounded,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter a pond name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'TARGET SPECIES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : const Color(0xFF64748B),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSpeciesCard(
                            'Shrimp',
                            Icons.waves_rounded,
                            theme,
                            isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildSpeciesCard(
                            'Tilapia',
                            Icons.set_meal_rounded,
                            theme,
                            isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader('Stocking Details', theme),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: PondStatTextField(
                            controller: _stockingQuantityController,
                            label: 'Stocking Density',
                            hint: '5000',
                            helperText: 'Total juveniles stocked',
                            prefixIcon: Icons.numbers_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 18,
                              ),
                              child: Text(
                                'pcs',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Required';
                              }
                              if ((int.tryParse(val) ?? 0) <= 0) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: PondStatTextField(
                            controller: _culturePeriodController,
                            label: 'Target Duration',
                            hint: '90',
                            prefixIcon: Icons.calendar_month_rounded,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(
                                right: 16,
                                top: 18,
                              ),
                              child: Text(
                                'days',
                                style: TextStyle(
                                  color: isDark ? Colors.white38 : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Required';
                              }
                              if ((int.tryParse(val) ?? 0) <= 0) {
                                return 'Invalid';
                              }
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
                      isSuccess: _isSuccess,
                      onPressed: (!_isFormValid || _isLoading || _isSuccess)
                          ? null
                          : _updatePond,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    IconData headerIcon = Icons.edit_rounded;
    if (_selectedSpecies == 'Shrimp') headerIcon = Icons.waves_rounded;
    if (_selectedSpecies == 'Tilapia') headerIcon = Icons.set_meal_rounded;

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(headerIcon),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(headerIcon, color: theme.colorScheme.primary, size: 28),
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
