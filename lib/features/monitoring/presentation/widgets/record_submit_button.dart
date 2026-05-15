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
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(
          context,
        ).colorScheme.copyWith(primary: themeColor),
      ),
      child: PrimaryButton(
        text: isLastParameter ? 'Save & Finish' : 'Save & Next',
        icon: isLastParameter
            ? Icons.check_circle_outline_rounded
            : Icons.arrow_forward_rounded,
        isLoading: isSaving,
        onPressed: isLastParameter ? onSaveFinish : onSaveNext,
      ),
    );
  }
}
