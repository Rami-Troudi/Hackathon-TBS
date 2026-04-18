import 'package:flutter/material.dart';
import 'package:senior_companion/app/theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme Extension — Status Colors
// ─────────────────────────────────────────────────────────────────────────────

/// A [ThemeExtension] that exposes semantic status colors aligned with the
/// [SeniorGlobalStatus] model (OK / WATCH / ACTION_REQUIRED).
///
/// Access it anywhere you have a [BuildContext]:
/// ```dart
/// final statusColors = Theme.of(context).extension<AppStatusColors>()!;
/// color: statusColors.ok
/// ```
@immutable
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors({
    required this.ok,
    required this.watch,
    required this.actionRequired,
    required this.info,
  });

  /// Color for the OK / all-clear status indicator.
  final Color ok;

  /// Color for the WATCH / needs-attention status indicator.
  final Color watch;

  /// Color for the ACTION_REQUIRED / urgent status indicator.
  final Color actionRequired;

  /// Color for informational / neutral UI elements.
  final Color info;

  @override
  AppStatusColors copyWith({
    Color? ok,
    Color? watch,
    Color? actionRequired,
    Color? info,
  }) {
    return AppStatusColors(
      ok: ok ?? this.ok,
      watch: watch ?? this.watch,
      actionRequired: actionRequired ?? this.actionRequired,
      info: info ?? this.info,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      ok: Color.lerp(ok, other.ok, t)!,
      watch: Color.lerp(watch, other.watch, t)!,
      actionRequired: Color.lerp(actionRequired, other.actionRequired, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStatusColors &&
          other.ok == ok &&
          other.watch == watch &&
          other.actionRequired == actionRequired &&
          other.info == info;

  @override
  int get hashCode => Object.hash(ok, watch, actionRequired, info);

  @override
  String toString() => 'AppStatusColors('
      'ok: $ok, watch: $watch, '
      'actionRequired: $actionRequired, info: $info)';
}

// ─────────────────────────────────────────────────────────────────────────────
// App Theme
// ─────────────────────────────────────────────────────────────────────────────

class AppTheme {
  const AppTheme._();

  /// The default light theme for Senior Companion.
  ///
  /// Typography is intentionally sized for senior readability:
  /// - [TextTheme.bodyLarge] is 18sp (up from Material default 16sp)
  /// - [TextTheme.bodyMedium] is 16sp (up from Material default 14sp)
  /// - [TextTheme.displayLarge] is 32sp / w700 for senior confirmation screens
  ///
  /// Tap targets respect the WCAG 2.1 minimum of 44px, with the senior
  /// [FilledButton] going to 56px for primary actions on senior screens.
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ── Theme Extensions ─────────────────────────────────────────────────
      extensions: const [
        AppStatusColors(
          ok: AppColors.statusOk,
          watch: AppColors.statusWatch,
          actionRequired: AppColors.statusActionRequired,
          info: AppColors.info,
        ),
      ],

      // ── Typography ───────────────────────────────────────────────────────
      //
      // All font sizes are slightly larger than Material defaults to support
      // the senior accessibility requirement of minimum 18sp body text.
      // See: docs/architecture.md — Design system section.
      textTheme: const TextTheme(
        // Used for senior confirmation screens ("I'm okay", incident dialogs).
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        // Used for section headings and screen titles.
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        headlineSmall: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        // Used for card titles and list item headings.
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Primary body text — 18sp for senior readability.
        bodyLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        // Secondary body text — 16sp minimum for legibility.
        bodyMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
        // Button labels — 16sp / w600 for clear tap target labelling.
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        labelSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),

      // ── App Bar ──────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardTheme(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── ElevatedButton ───────────────────────────────────────────────────
      // General-purpose elevated button. 48px height meets WCAG minimum.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── FilledButton ─────────────────────────────────────────────────────
      // Senior primary action button. Full-width, 56px tall for large tap target.
      // Use this for "I'm okay", "Confirm", and other primary senior actions.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── TextButton ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── InputDecoration ──────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),

      // ── Switch ───────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.surface;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
      ),

      // ── ListTile ─────────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 12,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── SnackBar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
