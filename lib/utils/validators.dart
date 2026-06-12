abstract class Validators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid email address';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'This field is required';
    if (v.trim().length < 2) return 'Must be at least 2 characters';
    return null;
  }

  static String? username(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username is required';
    if (v.trim().length < 3) return 'Username must be at least 3 characters';
    final re = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!re.hasMatch(v.trim())) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final re = RegExp(r'^\+?[0-9]{8,15}$');
    return re.hasMatch(v.trim()) ? null : 'Enter a valid phone number';
  }
}
