import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central color + type tokens for PupCheck.
/// Mirrors the HTML mockup: deep teal-green primary, warm amber accent,
/// coral for concerning results, soft green for healthy ones.
class AppColors {
  static const bg = Color(0xFFF7FAF9);
  static const surface = Color(0xFFFFFFFF);

  static const ink = Color(0xFF0C2649);
  static const inkSoft = Color(0xFF5B6B73);

  static const primary = Color(0xFF0C2649);
  static const primaryDark = Color(0xFF071A33);

  static const accent = Color(0xFF18AA95);
  static const accentSoft = Color(0xFFDDF5F0);

  static const alert = Color(0xFFD9534F);
  static const alertSoft = Color(0xFFFBE4E2);

  static const success = Color(0xFF18AA95);
  static const successSoft = Color(0xFFDDF5F0);

  static const line = Color(0xFFDCE6E3);
}

class AppText {
  static TextStyle display({double size = 22, Color? color, FontWeight w = FontWeight.w700}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: w, color: color ?? AppColors.ink, letterSpacing: -0.3);

  static TextStyle eyebrow({Color? color}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
        color: color ?? AppColors.accent,
      );

  static TextStyle body({double size = 14, Color? color, FontWeight w = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: color ?? AppColors.ink);

  static TextStyle muted({double size = 12, FontWeight w = FontWeight.w500}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: AppColors.inkSoft);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.surface,
    ),
    textTheme: GoogleFonts.interTextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        elevation: 0,
      ),
    ),
  );
}

/// Small reusable "pill" badge, e.g. severity tags.
class Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  const Pill({super.key, required this.text, required this.fg, required this.bg});

  factory Pill.alert(String text) => Pill(text: text, fg: AppColors.alert, bg: AppColors.alertSoft);
  factory Pill.success(String text) => Pill(text: text, fg: AppColors.success, bg: AppColors.successSoft);
  factory Pill.accent(String text) => Pill(text: text, fg: AppColors.accent, bg: AppColors.accentSoft);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

/// The dashed scan-ring signature motif used across the app.
class ScanRingIcon extends StatelessWidget {
  final Color color;
  final double size;
  const ScanRingIcon({super.key, this.color = AppColors.accent, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
    );
  }
}
