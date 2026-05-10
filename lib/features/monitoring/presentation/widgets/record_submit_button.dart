import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class RecordSubmitButton extends StatelessWidget {
  final bool isSaving;
  final Color themeColor;
  final bool isLastParameter;
  final VoidCallback onSaveNext;
  final VoidCallback onSaveFinish;

  const RecordSubmitButton({
    super.key,
    required this.isSaving,
    required this.themeColor,
    required this.isLastParameter,
    required this.onSaveNext,
    required this.onSaveFinish,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: themeColor),
            ),
            onPressed: isSaving ? null : onSaveNext,
            child: Text(
              isLastParameter ? "Save & Finish" : "Save & Next",
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(primary: themeColor),
            ),
            child: PrimaryButton(
              text: 'Save',
              icon: Icons.check_circle_outline_rounded,
              isLoading: isSaving,
              onPressed: onSaveFinish,
            ),
          ),
        ),
      ],
    );
  }
}
