import 'package:flutter/material.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/core/widgets/secondary_button.dart';

class DestructiveDialog extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final Future<void> Function() onConfirm;

  const DestructiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = "Delete",
    this.cancelText = "Cancel",
    required this.onConfirm,
  });

  @override
  State<DestructiveDialog> createState() => _DestructiveDialogState();
}

class _DestructiveDialogState extends State<DestructiveDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textDark = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textDark,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          widget.content,
          style: TextStyle(
            color: textMuted,
            height: 1.5,
            fontSize: 15,
          ),
        ),
        actionsPadding: const EdgeInsets.only(
          bottom: 20,
          right: 20,
          left: 20,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: widget.cancelText,
                  onPressed: _isDeleting ? null : () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: widget.confirmText,
                  isLoading: _isDeleting,
                  onPressed: _isDeleting
                      ? null
                      : () async {
                          setState(() => _isDeleting = true);
                          try {
                            await widget.onConfirm();
                            if (context.mounted) {
                              setState(() => _isDeleting = false);
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => _isDeleting = false);
                              SnackbarHelper.showError(
                                context,
                                "Failed to delete: $e",
                              );
                            }
                          }
                        },
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
