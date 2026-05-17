import 'package:flutter/material.dart';

import '../theme/app_metrics.dart';

class PondStatDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  // New exposed capabilities
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final void Function(T?)? onSaved;

  PondStatDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    this.hint,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.autovalidateMode,
    this.onSaved,
  }) : assert(
         value == null || items.any((item) => item.value == value),
         'Dropdown value must match one of the provided items.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isDisabled = onChanged == null;

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label.toUpperCase(),
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: isDark
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
          ),
          DropdownButtonFormField<T>(
            // ignore: deprecated_member_use
            value: value,
            isExpanded: true,
            dropdownColor: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(context.metrics.radiusMedium),
            menuMaxHeight: 300,
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: 20)
                  : null,
            ),
            items: items,
            selectedItemBuilder: (BuildContext context) {
              return items.map<Widget>((DropdownMenuItem<T> item) {
                final Widget child = item.child;
                if (child is Text) {
                  return Text(
                    child.data ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  );
                }
                return child;
              }).toList();
            },
            onChanged: onChanged,
            validator: validator,
            focusNode: focusNode,
            autovalidateMode: autovalidateMode,
            onSaved: onSaved,
            style: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
