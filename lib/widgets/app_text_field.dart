import 'package:flutter/material.dart';
import '../core/app_style.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: AppStyle.cartoonInputDecoration(
        labelText: label,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: Colors.black54),
      ),
    );
  }
}
