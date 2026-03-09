class StringUtils {
  /// Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Capitalize all words
  static String capitalizeWords(String text) {
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Truncate string and add ellipsis
  static String truncate(String text, int length, {String ellipsis = '...'}) {
    if (text.length <= length) return text;
    return text.substring(0, length) + ellipsis;
  }

  /// Remove extra whitespace
  static String removeExtraWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Check if string is null or empty
  static bool isNullOrEmpty(String? text) {
    return text == null || text.isEmpty;
  }

  /// Check if string is null, empty or whitespace
  static bool isNullOrWhiteSpace(String? text) {
    return text == null || text.trim().isEmpty;
  }

  /// Convert string to slug (lowercase with hyphens)
  static String toSlug(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
  }

  /// Mask sensitive information (e.g., for email)
  static String maskEmail(String email) {
    if (email.isEmpty) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final localPart = parts[0];
    final domain = parts[1];

    if (localPart.length <= 2) {
      return '***@$domain';
    }

    final masked = localPart[0] + '*' * (localPart.length - 2) + localPart[localPart.length - 1];
    return '$masked@$domain';
  }

  /// Convert camelCase to spaces
  static String fromCamelCase(String text) {
    return text
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])[A-Z]'),
          (Match m) => ' ${m.group(0)}',
        )
        .toLowerCase()
        .trim();
  }
}
