import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design System: "Precision Engineering" - High-End Pro IDE Aesthetic
/// No rounded corners (0px radius), monochromatic charcoal base,
/// tonal layering for depth, technical authority in typography.
class AppColors {
  // ── Surface Hierarchy (Tonal Layering) ─────────────────────────────────────
  static const Color surface = Color(0xFF0e0e0e);           // Main Stage
  static const Color surfaceContainerLow = Color(0xFF131313); // Side Panels
  static const Color surfaceContainer = Color(0xFF191a1a);    // Containers
  static const Color surfaceContainerHigh = Color(0xFF1f2020); // Active/Modals
  static const Color surfaceContainerHighest = Color(0xFF252626); // Floating
  static const Color surfaceVariant = Color(0xFF252626);      // Hover states
  static const Color surfaceContainerLowest = Color(0xFF000000); // Input fields

  // ── Primary Accent (Use sparingly - Success/Active states only) ─────────────
  static const Color primary = Color(0xFFb1cad7);             // Signature blue
  static const Color primaryContainer = Color(0xFF334a55);   // Primary dark
  static const Color onPrimary = Color(0xFF2c434e);          // Text on primary

  // ── Semantic Colors ────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFe7e5e4);           // Primary text
  static const Color onSurfaceVariant = Color(0xFFa8a29e);   // Secondary text
  static const Color outline = Color(0xFF484848);            // Ghost borders
  static const Color outlineVariant = Color(0xFF484848);    // For data grids

  static const Color success = Color(0xFF22c55e);             // Success green
  static const Color error = Color(0xFFbb5551);              // Error dim (focused calm)
  static const Color warning = Color(0xFFd97706);            // Warning amber

  // ── Legacy Aliases (for existing code compatibility) ────────────────────────
  static const Color bg = surface;
  static const Color card = surfaceContainer;
  static const Color border = surfaceVariant;
  static const Color accent = primary;
  static const Color accentDim = primaryContainer;
  static const Color textPrimary = onSurface;
  static const Color textSecondary = onSurfaceVariant;
  static const Color textMuted = outline;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,

      // ── Color Scheme ─────────────────────────────────────────────────────────
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.surfaceContainerHighest,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
      ),

      // ── Typography - Technical Authority ──────────────────────────────────────
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayMedium: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.01,
          color: AppColors.onSurface,
        ),
        titleLarge: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurface,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.onSurfaceVariant,
        ),
        labelMedium: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05,
          color: AppColors.onSurfaceVariant,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurfaceVariant,
        ),
      ),

      // ── Cards - No dividers, tonal separation ────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // 0px radius - Pro IDE
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input Fields - Carved out effect ─────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outline, width: 2),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outline, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.outline),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),

      // ── Buttons - Industrial Suite ────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // 0px radius - Pro IDE
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            letterSpacing: 0.02,
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          side: const BorderSide(color: AppColors.outline, width: 1),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      // ── Icon Buttons ─────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onSurfaceVariant,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
      ),

      // ── Chips - Rectangular status tags ──────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.05,
          color: AppColors.onSurface,
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Dividers - Ghost Border Fallback ─────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: AppColors.outline.withValues(alpha: 0.15), // 15% opacity
        thickness: 1,
        space: 1,
      ),

      // ── Scrollbar - Thin, technical ──────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.outline),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(0), // 0px radius
        thumbVisibility: WidgetStateProperty.all(true),
      ),

      // ── Tooltip - Sharp corners, surface-highest ─────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHighest,
          borderRadius: BorderRadius.zero,
        ),
        textStyle: const TextStyle(
          color: AppColors.onSurface,
          fontSize: 12,
        ),
      ),

      // ── Dialog / Modal - Glass effect ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceContainerHighest.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),

      // ── Drawer - Side panels ─────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),

      // ── List Tiles - No dividers, spacing ───────────────────────────────────
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        dense: true,
        textColor: AppColors.onSurface,
        iconColor: AppColors.onSurfaceVariant,
      ),

      // ── Progress Indicators ───────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceContainer,
      ),

      // ── Snackbar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: const TextStyle(color: AppColors.onSurface),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Gradient for Primary CTA - "Machined Metal" sheen
class PrimaryGradient {
  static const LinearGradient metalSheen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryContainer],
  );
}

/// Ghost Border - 15% opacity outline for data grids
/// #484848 at 15% opacity = 0x26484848
class GhostBorder extends BorderSide {
  const GhostBorder()
      : super(
          color: const Color(0x26484848),
          width: 1,
        );
}

/// Ghost border color for inline usage
const ghostBorderColor = Color(0x26484848);
