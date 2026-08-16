import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Builds the LocalLens [ThemeData] for a given [brightness].
///
/// Visual language: Clean, high-contrast, distraction-free civic timeline.
/// Solid semantic tones and subtle border lines create a trustworthy,
/// legible interface.
ThemeData buildAppTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.seed,
    brightness: brightness,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
  );
  final textTheme = _buildTextTheme(base.textTheme);

  return base.copyWith(
    scaffoldBackgroundColor: isDark
        ? AppColors.darkScaffold
        : AppColors.lightScaffold,
    textTheme: textTheme,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      iconTheme: IconThemeData(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? AppColors.darkCard : AppColors.lightSurface,
      surfaceTintColor: isDark
          ? scheme.primaryContainer.withValues(alpha: 0.06)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      thickness: 1,
      space: 1,
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(
        color: isDark ? AppColors.darkBorder : scheme.outlineVariant,
      ),
      labelStyle: textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark
          ? const Color(0xFF161616)
          : scheme.surfaceContainerLowest.withValues(alpha: 0.4),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : scheme.outlineVariant,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.darkBorder : scheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.brand, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: AppColors.brand,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : scheme.outline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.brand,
        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: isDark ? AppColors.darkBorder : scheme.outlineVariant,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? const Color(0xFF1E1E1E)
          : const Color(0xFF23262B),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: scheme.primaryContainer,
        selectedForegroundColor: scheme.onPrimaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.brand),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

TextTheme _buildTextTheme(TextTheme base) {
  final w800 = FontWeight.w800;
  final w700 = FontWeight.w700;
  final w600 = FontWeight.w600;

  return base.copyWith(
    displayLarge: base.displayLarge?.copyWith(
      fontWeight: w800,
      letterSpacing: -1.2,
    ),
    displayMedium: base.displayMedium?.copyWith(
      fontWeight: w800,
      letterSpacing: -0.8,
    ),
    displaySmall: base.displaySmall?.copyWith(fontWeight: w800),
    headlineLarge: base.headlineLarge?.copyWith(fontWeight: w800),
    headlineMedium: base.headlineMedium?.copyWith(fontWeight: w800),
    headlineSmall: base.headlineSmall?.copyWith(fontWeight: w700),
    titleLarge: base.titleLarge?.copyWith(fontWeight: w700),
    titleMedium: base.titleMedium?.copyWith(fontWeight: w600),
    titleSmall: base.titleSmall?.copyWith(fontWeight: w600),
    bodyLarge: base.bodyLarge?.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    bodyMedium: base.bodyMedium?.copyWith(
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400),
    labelLarge: base.labelLarge?.copyWith(fontWeight: w600),
    labelMedium: base.labelMedium?.copyWith(fontWeight: w600),
  );
}
