import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get h1 => GoogleFonts.manrope(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get h2 => GoogleFonts.manrope(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get h3 => GoogleFonts.manrope(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodyMedium => GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get bodySmall => GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      );

  static TextStyle get button => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
