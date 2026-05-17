extension StringExtensions on String? {
  /// Safely extracts the initials from a string.
  /// Handles null, completely empty, or whitespace-only strings safely.
  String get initials {
    if (this == null) return '?';

    final sanitized = this!.trim();
    if (sanitized.isEmpty) return '?';

    final parts = sanitized.split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
