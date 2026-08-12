import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
    this.onChanged,
    this.validator,
    this.premium = false,
  });

  final TextEditingController? controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    final decoration = premium
        ? BoxDecoration(
            color: Colors.white,
            borderRadius: borderRadius,
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : const BoxDecoration();

    final inputDecoration = InputDecoration(
      labelText: label,
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: premium ? const Color(0xFFE8541A) : null),
      suffixIcon: suffix,
      border: premium ? InputBorder.none : const OutlineInputBorder(),
      enabledBorder: premium ? InputBorder.none : const OutlineInputBorder(),
      focusedBorder: premium ? InputBorder.none : const OutlineInputBorder(),
      filled: premium,
      fillColor: premium ? Colors.white : null,
      contentPadding: premium
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 14)
          : null,
    );

    final field = TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: inputDecoration,
      onChanged: onChanged,
      validator: validator,
    );

    if (!premium) return field;

    return Container(decoration: decoration, child: field);
  }
}
