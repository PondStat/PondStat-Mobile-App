import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';

class CreateParameterDialog extends ConsumerStatefulWidget {
  final String pondId;
  final int tabIndex;
  final String? customType;

  const CreateParameterDialog({
    super.key,
    required this.pondId,
    required this.tabIndex,
    this.customType,
  });

  @override
  ConsumerState<CreateParameterDialog> createState() => _CreateParameterDialogState();
}

class _CreateParameterDialogState extends ConsumerState<CreateParameterDialog> {
  final TextEditingController _customParamNameController = TextEditingController();
  final TextEditingController _customParamUnitController = TextEditingController();
  String? selectedCategory;

  @override
  void dispose() {
    _customParamNameController.dispose();
    _customParamUnitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        "New Parameter",
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PondStatTextField(
              controller: _customParamNameController,
              label: "Parameter Name",
              hint: "e.g., Turbidity",
              prefixIcon: Icons.science_outlined,
            ),
            const SizedBox(height: 12),
            PondStatTextField(
              controller: _customParamUnitController,
              label: "Unit",
              hint: "e.g., NTU",
              prefixIcon: Icons.straighten_rounded,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: "Graph Category",
                prefixIcon: const Icon(
                  Icons.category_rounded,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Chemical',
                  child: Text('Chemical'),
                ),
                DropdownMenuItem(
                  value: 'Physical',
                  child: Text('Physical'),
                ),
                DropdownMenuItem(
                  value: 'Biological',
                  child: Text('Biological'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  selectedCategory = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            "Cancel",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            if (_customParamNameController.text.isNotEmpty &&
                _customParamUnitController.text.isNotEmpty &&
                selectedCategory != null) {
              String type = widget.customType ??
                  ['daily', 'weekly', 'biweekly'][widget.tabIndex];
              await ref.read(monitoringRepositoryProvider).addCustomParameter(
                    label: _customParamNameController.text.trim(),
                    unit: _customParamUnitController.text.trim(),
                    type: type,
                    category: selectedCategory!,
                    pondId: widget.pondId,
                  );
              if (context.mounted) Navigator.pop(context);
            } else {
              SnackbarHelper.showInfo(context, "Please fill out all fields");
            }
          },
          child: const Text(
            "Create",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
