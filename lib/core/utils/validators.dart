class Validators {
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 10) return 'Enter a valid mobile number';
    return null;
  }

  static String? requiredText(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }
}
