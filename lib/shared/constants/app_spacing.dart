import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Spacing scale
// ─────────────────────────────────────────────────────────────────────────────

/// A fixed spacing scale used across the entire application.
///
/// Always prefer these named constants over raw numbers in padding,
/// margin, and SizedBox values. This makes spacing changes global.
///
/// Scale reference:
/// ```
/// xs   =  4px  — tight internal padding (icon gaps, badge offsets)
/// sm   =  8px  — small gaps between related items
/// md   = 16px  — standard content padding
/// lg   = 24px  — section separation
/// xl   = 32px  — large section breaks
/// xxl  = 48px  — senior tap target height, major screen sections
/// xxxl = 64px  — hero spacing, splash screen vertical rhythm
/// ```
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  /// 48px — used for senior minimum tap target height and major section breaks.
  static const double xxl = 48.0;

  /// 64px — used for hero areas and splash screen vertical rhythm.
  static const double xxxl = 64.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// Prebuilt gap widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Prebuilt [SizedBox] gap widgets for use in [Column] and [Row] children.
///
/// Vertical gaps (for use in [Column]):
/// ```dart
/// Column(children: [
///   Text('Hello'),
///   Gaps.v16,
///   Text('World'),
/// ])
/// ```
///
/// Horizontal gaps (for use in [Row]):
/// ```dart
/// Row(children: [
///   Icon(Icons.check),
///   Gaps.h8,
///   Text('Done'),
/// ])
/// ```
class Gaps {
  const Gaps._();

  // ── Vertical ───────────────────────────────────────────────────────────────

  static const v4 = SizedBox(height: AppSpacing.xs);
  static const v8 = SizedBox(height: AppSpacing.sm);
  static const v16 = SizedBox(height: AppSpacing.md);
  static const v24 = SizedBox(height: AppSpacing.lg);
  static const v32 = SizedBox(height: AppSpacing.xl);
  static const v48 = SizedBox(height: AppSpacing.xxl);
  static const v64 = SizedBox(height: AppSpacing.xxxl);

  // ── Horizontal ─────────────────────────────────────────────────────────────

  static const h4 = SizedBox(width: AppSpacing.xs);
  static const h8 = SizedBox(width: AppSpacing.sm);
  static const h16 = SizedBox(width: AppSpacing.md);
  static const h24 = SizedBox(width: AppSpacing.lg);
  static const h32 = SizedBox(width: AppSpacing.xl);
}

// ─────────────────────────────────────────────────────────────────────────────
// Border radius scale
// ─────────────────────────────────────────────────────────────────────────────

/// A fixed border radius scale aligned with the application's shape language.
///
/// Use the raw [double] constants when constructing [BorderRadius] manually,
/// or use the prebuilt [BorderRadius] getters for common cases.
///
/// Shape guidelines:
/// - Prefer [md] (12px) for cards, inputs, and most containers.
/// - Prefer [lg] (16px) for sheets and modals.
/// - Prefer [xl] (24px) for large hero cards on senior screens.
/// - Use [pill] (999px) for status chips, badges, and rounded tags.
class AppBorderRadius {
  const AppBorderRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  /// Use for status chips, tags, and fully-rounded pill shapes.
  static const double pill = 999.0;

  // ── Prebuilt BorderRadius ──────────────────────────────────────────────────

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get pillAll => BorderRadius.circular(pill);

  /// Top-only rounded corners — useful for bottom sheets.
  static BorderRadius get lgTop => const BorderRadius.vertical(
        top: Radius.circular(lg),
      );

  /// Bottom-only rounded corners.
  static BorderRadius get lgBottom => const BorderRadius.vertical(
        bottom: Radius.circular(lg),
      );
}