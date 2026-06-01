import 'package:flutter/material.dart';

class AppStyle {
  // Cartoonish-Minimalist Theme Colors
  static const Color bgCleanWhite = Colors.white;
  static const Color textBlack = Colors.black;
  static const Color borderBlack = Colors.black;
  
  // Neo-brutalist accent colors to give it that "wow" Mobbin feel
  static const Color primaryYellow = Color(0xFFFFF176); // Bright cartoonish yellow
  static const Color accentPurple = Color(0xFF7B3EFF); // Neon purple
  static const Color accentGreen = Color(0xFF2ECC71); // Cartoon green
  static const Color accentRed = Color(0xFFE74C3C); // Cartoon red
  static const Color backgroundLight = Color(0xFFF7F7F9); // Light cool gray background

  /// Core Mobbin-style box decoration: Clean background, 2px black borders,
  /// circular corners (12), and solid black shadow with offset (no blur).
  static BoxDecoration cartoonDecoration({
    Color color = Colors.white,
    double borderWidth = 2.0,
    double borderRadius = 12.0,
    Offset shadowOffset = const Offset(4, 4),
    Color shadowColor = Colors.black,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderBlack, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor,
          offset: shadowOffset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  /// Cartoonish input decoration for standard text fields
  static InputDecoration cartoonInputDecoration({
    required String labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentRed, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentRed, width: 2),
      ),
    );
  }
}
