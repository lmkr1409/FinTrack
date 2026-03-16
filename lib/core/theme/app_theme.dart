import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Material 3 dark theme for FinTrack — "High-Contrast Fintech Dark".
class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      // 60% deep neutral
      surface: AppColors.surface,
      // 30% containers
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.cardBackground,
      surfaceContainerHighest: AppColors.cardElevated,
      // 10% accent
      primary: AppColors.primary,
      onPrimary: AppColors.surfaceDim,
      primaryContainer: AppColors.navIndicator,
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: AppColors.surfaceDim,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.surfaceDim,
      // Functional
      error: AppColors.expense,
      onError: AppColors.surfaceDim,
      // Text / icons
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,

      // ─── AppBar ─────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),

      // ─── Navigation Bar (bottom) ───────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        indicatorColor: AppColors.navIndicator,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
          }
          return const TextStyle(fontSize: 12, color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),

      // ─── Navigation Drawer ─────────────────────────────
      navigationDrawerTheme: const NavigationDrawerThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ─── Cards — base styling (glassmorphism applied via GlassCard widget)
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),

      // ─── Dialogs ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),

      // ─── Bottom Sheet ───────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.cardElevated,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black54,
      ),

      // ─── Input fields ──────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixStyle: const TextStyle(color: AppColors.textSecondary),
      ),

      // ─── Buttons ────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surfaceDim,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      ),

      // ─── Segmented Button ──────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.navIndicator;
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.textSecondary;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: AppColors.border)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        ),
      ),

      // ─── Chips ──────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceContainer,
        side: const BorderSide(color: AppColors.border),
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // ─── FAB ────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surfaceDim,
      ),

      // ─── Divider ────────────────────────────────────────
      dividerTheme: const DividerThemeData(color: AppColors.borderSubtle, thickness: 0.5),

      // ─── Text ───────────────────────────────────────────
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textMuted),
        labelLarge: TextStyle(color: AppColors.textPrimary),
        labelMedium: TextStyle(color: AppColors.textSecondary),
        labelSmall: TextStyle(color: AppColors.textMuted),
      ),

      // ─── Progress Indicator ─────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearTrackColor: AppColors.surfaceContainer,
        color: AppColors.primary,
      ),

      // ─── ListTile ───────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.textPrimary,
        iconColor: AppColors.textSecondary,
      ),

      // ─── Badge ──────────────────────────────────────────
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.secondary,
        textColor: Colors.white,
      ),

      // ─── DropdownMenu ───────────────────────────────────
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainer,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
        ),
      ),
    );
  }
}
