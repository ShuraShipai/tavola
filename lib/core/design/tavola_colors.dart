import 'package:flutter/material.dart';

/// Slate-and-amber palette from the Tavola design handoff.
abstract final class TavolaColors {
  static const primary = Color(0xFF1E293B);
  static const primaryDark = Color(0xFF16202E);
  static const secondary = Color(0xFF475569);
  static const accent = Color(0xFFF59E0B);
  static const accentDark = Color(0xFFD97706);
  static const accentLight = Color(0xFFFEF3C7);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const textInverse = Color(0xFFF8FAFC);

  static const success = Color(0xFF22C55E);
  static const successLight = Color(0xFFDCFCE7);
  static const warning = accent;
  static const warningLight = accentLight;
  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFEE2E2);
  static const info = Color(0xFF3B82F6);
  static const infoLight = Color(0xFFDBEAFE);
  static const disabled = Color(0xFFE2E8F0);
  static const disabledText = Color(0xFF94A3B8);
  static const shadow = Color(0x260F172A);
  static const overlay = Color(0x800F172A);

  static const darkBackground = Color(0xFF0F172A);
  static const darkSurface = Color(0xFF1E293B);
  static const darkSurfaceVariant = Color(0xFF334155);
  static const darkBorder = Color(0xFF475569);
  static const darkTextPrimary = Color(0xFFF8FAFC);
  static const darkTextSecondary = Color(0xFFCBD5E1);
}
