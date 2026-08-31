class Validators {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _phonePattern = RegExp(r'^\+?\d{7,15}$');
  static final RegExp _pincodePattern = RegExp(r'^\d{6}$');

  static String? requiredText(
    String? value, {
    String message = 'This field is required',
  }) {
    if ((value ?? '').trim().isEmpty) return message;
    return null;
  }

  static String? email(
    String? value, {
    String emptyMessage = 'Enter your email address',
    String invalidMessage = 'Enter a valid email address',
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return emptyMessage;
    if (!_emailPattern.hasMatch(text)) return invalidMessage;
    return null;
  }

  static String? phone(
    String? value, {
    String emptyMessage = 'Enter your phone number',
    String invalidMessage = 'Enter a valid mobile number',
  }) {
    final text = (value ?? '').trim().replaceAll(RegExp(r'[\s-]'), '');
    if (text.isEmpty) return emptyMessage;
    if (!_phonePattern.hasMatch(text)) return invalidMessage;
    return null;
  }

  static String? emailOrPhone(
    String? value, {
    String emptyMessage = 'Enter your email or phone number',
    String invalidMessage = 'Enter a valid email or phone number',
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return emptyMessage;

    if (_emailPattern.hasMatch(text)) return null;

    final normalizedPhone = text.replaceAll(RegExp(r'[\s-]'), '');
    if (_phonePattern.hasMatch(normalizedPhone)) return null;

    return invalidMessage;
  }

  static String normalizePhone(String value) {
    return value.trim().replaceAll(RegExp(r'[\s-]'), '');
  }

  static String? password(
    String? value, {
    String message = 'Enter your password',
    int minLength = 0,
    String? lengthMessage,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return message;
    if (minLength > 0 && text.length < minLength) {
      return lengthMessage ?? 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? name(
    String? value, {
    String emptyMessage = 'Enter your full name',
    int minLength = 2,
    String? lengthMessage,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return emptyMessage;
    if (text.length < minLength) {
      return lengthMessage ?? 'Name is too short';
    }
    return null;
  }

  static String? pincode(
    String? value, {
    String emptyMessage = 'Enter your pincode',
    String invalidMessage = 'Enter a valid 6-digit pincode',
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return emptyMessage;
    if (!_pincodePattern.hasMatch(text)) return invalidMessage;
    return null;
  }
}
