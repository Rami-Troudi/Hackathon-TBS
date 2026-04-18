import 'package:flutter/material.dart';

class AppColors {
  // ── Brand / Design System (senior-flow-aid aligned) ──────────────────────
  // Warm cream + sage + terracotta
  static const background = Color(0xFFFFF9F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFF6F1E8);

  static const primary = Color(0xFF4C7C63); // sage
  static const primarySoft = Color(0xFFE2EFE6);
  static const accent = Color(0xFFC9835E); // terracotta
  static const accentSoft = Color(0xFFF7E6DA);

  // ── Severity ───────────────────────────────────────────────────────────────
  static const warning = Color(0xFFD39A3F);
  static const critical = Color(0xFFC45452); // warm red, not neon
  static const info = Color(0xFF5A84B5);
  static const success = Color(0xFF4E8A66);

  // ── Global Status ──────────────────────────────────────────────────────────
  static const statusOk = success;
  static const statusWatch = warning;
  static const statusActionRequired = critical;

  // ── Text ───────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF2E3A32);
  static const textSecondary = Color(0xFF5C6E61);
  static const textMuted = Color(0xFF77867B);

  // ── Utility ────────────────────────────────────────────────────────────────
  static const divider = Color(0xFFE6DED0);
  static const input = Color(0xFFF8F4EC);
}
