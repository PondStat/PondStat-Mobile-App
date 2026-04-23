import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PondStatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;
  final Widget? suffixIcon;
  final bool obscureText;
  final List<TextInputFormatter>? inputFormatters;
  final String? helperText;

  const PondStatTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
    this.obscureText = false,
    this.inputFormatters,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: isDark
                  ? colorScheme.onSurfaceVariant
                  : const Color(0xFF64748B),
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
          textInputAction: textInputAction,
          inputFormatters: inputFormatters,
          onFieldSubmitted: onSubmitted,
          onChanged: onChanged,
          validator: validator,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
            // Rest of the styling is inherited from app_theme.dart's inputDecorationTheme
          ),
        ),
      ],
    );
  }
}
