import 'package:flutter/material.dart';

class PondStatDropdownField<T> extends StatelessWidget {
  final T? value;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;

  const PondStatDropdownField({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    this.hint,
    this.prefixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ),
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
          ),
          items: items,
          onChanged: onChanged,
          validator: validator,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
            fontFamily:
                'Roboto', // Default material font to avoid weird inheritance issues
          ),
        ),
      ],
    );
  }
}
