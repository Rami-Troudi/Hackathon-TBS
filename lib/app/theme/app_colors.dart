import 'package:flutter/material.dart';

class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary = Color(0xFF2B6CB0);
  static const secondary = Color(0xFF2F855A);

  // ── Severity ───────────────────────────────────────────────────────────────
  static const warning = Color(0xFFB7791F);
  static const critical = Color(0xFFC53030);
  static const info = Color(0xFF2B6CB0);
  static const success = Color(0xFF276749);

  // ── Global Status ──────────────────────────────────────────────────────────
  /// Used for OK state indicators — accessible dark green.
  static const statusOk = Color(0xFF276749);

  /// Used for WATCH state indicators — accessible dark amber.
  static const statusWatch = Color(0xFF975A16);

  /// Used for ACTION_REQUIRED state indicators — same as critical.
  static const statusActionRequired = Color(0xFFC53030);

  // ── Surfaces ───────────────────────────────────────────────────────────────
  static const background = Color(0xFFF7FAFC);
  static const surface = Colors.white;

  /// Slightly warmer background used on senior-facing screens.
  static const seniorBackground = Color(0xFFF0F4F8);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A202C);
  static const textSecondary = Color(0xFF4A5568);

  // ── Utility ────────────────────────────────────────────────────────────────
  static const divider = Color(0xFFE2E8F0);
}