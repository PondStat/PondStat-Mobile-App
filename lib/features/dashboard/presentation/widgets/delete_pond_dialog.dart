import 'package:flutter/material.dart';

class DeletePondDialog extends StatefulWidget {
  final String pondName;

  const DeletePondDialog({
    super.key,
    required this.pondName,
  });

  @override
  State<DeletePondDialog> createState() => _DeletePondDialogState();
}

class _DeletePondDialogState extends State<DeletePondDialog> {
  String _typedName = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool isMatch = _typedName.trim().toUpperCase() == 'DELETE';

    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Delete Pond?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Are you sure you want to delete '${widget.pondName}'? This action is permanent and will erase all data, measurements, and history associated with it.",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Type 'DELETE' to confirm:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            autofocus: true,
            onChanged: (val) => setState(() => _typedName = val),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? Colors.white12 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            "Cancel",
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: Colors.white,
            disabledBackgroundColor: isDark
                ? Colors.white12
                : Colors.grey.shade300,
            disabledForegroundColor: isDark
                ? Colors.white38
                : Colors.grey.shade500,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          onPressed: isMatch
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text(
            "Delete Forever",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
