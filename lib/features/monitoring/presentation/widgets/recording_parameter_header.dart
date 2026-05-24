import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class RecordingParameterHeader extends StatelessWidget {
  final ParameterItem selectedParameter;
  final String? selectedDocId;
  final Color themeColor;
  final Color textDark;
  final bool isWizardStarted;
  final int wizardStepIndex;
  final int wizardTotalSteps;
  final VoidCallback onDeletePressed;

  const RecordingParameterHeader({
    super.key,
    required this.selectedParameter,
    required this.selectedDocId,
    required this.themeColor,
    required this.textDark,
    required this.isWizardStarted,
    required this.wizardStepIndex,
    required this.wizardTotalSteps,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    final showDeleteButton = selectedDocId != null &&
        selectedParameter.createdBy == currentUserUid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress Indicator
        if (isWizardStarted && wizardTotalSteps > 0) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Step ${wizardStepIndex + 1} of $wizardTotalSteps",
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      "${((wizardStepIndex + 1) / wizardTotalSteps * 100).toInt()}%",
                      style: TextStyle(
                        color: themeColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (wizardStepIndex + 1) / wizardTotalSteps,
                    backgroundColor: themeColor.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selectedParameter.icon,
                      color: themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RECORDING",
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            selectedParameter.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showDeleteButton)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
                onPressed: onDeletePressed,
              ),
          ],
        ),
      ],
    );
  }
}
