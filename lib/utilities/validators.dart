class Validator {
  static String? notEmpty(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a value';
    return null;
  }

  static String? age(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n < 10) return 'Please enter a valid age';
    return null;
  }

  static String? phoneNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a phone number';
    // Basic phone validation - allows digits, spaces, dashes, parentheses, and +
    final phoneRegex = RegExp(r'^[\d\s\-\+\(\)]+$');
    if (!phoneRegex.hasMatch(v.trim())) return 'Please enter a valid phone number';
    // Check if it has at least 10 digits
    final digitsOnly = v.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 10) return 'Phone number must have at least 10 digits';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please enter a username';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    if (v.trim().length > 20) return 'Username must be less than 20 characters';
    // Allow alphanumeric and underscore
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(v.trim())) return 'Username can only contain letters, numbers, and underscores';
    return null;
  }
}
