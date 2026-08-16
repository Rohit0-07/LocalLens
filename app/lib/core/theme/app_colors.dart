import 'package:flutter/material.dart';

/// LocalLens clean design tokens.
///
/// Clean, high-contrast, distraction-free civic design system inspired by
/// leading modern community & civic platforms. Solid semantic tones replace
/// loud multi-color gradients for enhanced readability and trust.
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────
  /// Material 3 seed. Authoritative civic Indigo.
  static const seed = Color(0xFF4F46E5);

  /// Primary brand color (buttons, links, active highlights).
  static const brand = Color(0xFF4F46E5);

  /// Darker brand tone for elevated contrast.
  static const brandDeep = Color(0xFF3730A3);

  /// Soft brand tonal tint for chips and active surface containers.
  static const brandLight = Color(0xFFEEF2FF);

  /// Backward-compatible solid brand list (replaces multi-color AI rainbow gradient).
  static const brandGradient = [
    Color(0xFF4F46E5),
    Color(0xFF4F46E5),
  ];

  /// Verified / Official civic blue.
  static const verified = Color(0xFF0284C7);

  /// Deeper verified blue for dark surfaces.
  static const verifiedDark = Color(0xFF38BDF8);

  /// Verified container background tint.
  static const verifiedSurface = Color(0xFFE0F2FE);

  /// Community-success emerald (wins, resolved highlights).
  static const win = Color(0xFF16A34A);

  /// Soft win container background tint.
  static const winSurface = Color(0xFFDCFCE7);

  // ── Surfaces (True OLED Black & Clean Light Surfaces) ─────────────────
  static const lightScaffold = Color(0xFFF8FAFC);
  static const darkScaffold = Color(0xFF000000);

  static const lightSurface = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF121212);

  /// Raised card / sheet tone in dark mode — one step lighter than
  /// [darkSurface] so elevated surfaces read as tonal overlays over the
  /// OLED-black scaffold instead of relying on borders alone.
  static const darkCard = Color(0xFF1A1A1A);

  static const lightBorder = Color(0xFFE2E8F0);
  static const darkBorder = Color(0xFF262626);

  /// Skeleton / shimmer placeholder tones.
  static const skeletonBase = Color(0xFFE2E8F0);
  static const skeletonBaseDark = Color(0xFF262626);
  static const skeletonHighlight = Color(0xFFF1F5F9);
  static const skeletonHighlightDark = Color(0xFF333333);

  // ── Status semantics ───────────────────────────────────────────────────
  static const urgent = Color(0xFFDC2626);
  static const review = Color(0xFFD97706);
  static const resolved = Color(0xFF16A34A);
  static const disputed = Color(0xFF9333EA);

  /// Anonymous-identity slate.
  static const anonMask = Color(0xFF64748B);

  /// Media watermark badge tones (verified vs unverified uploads).
  static const watermarkVerified = Color(0xFF2E7D32);
  static const watermarkVerifiedSurface = Color(0xFFE8F5E9);
  static const watermarkUnverified = Color(0xFFE65100);
  static const watermarkUnverifiedSurface = Color(0xFFFFF8E1);

  // ── Clean Category Colors ──────────────────────────────────────────────
  static const categoryColors = <String, Color>{
    'road': Color(0xFFB45309),
    'water': Color(0xFF0284C7),
    'power': Color(0xFFD97706),
    'lighting': Color(0xFF7C3AED),
    'waste': Color(0xFF15803D),
    'sanitation': Color(0xFF15803D),
    'sewage': Color(0xFF78350F),
    'other': Color(0xFF0F766E),
  };

  static const defaultCategoryColor = Color(0xFF0F766E);

  /// Returns the solid primary color for a category.
  static Color categoryColorFor(String category) =>
      categoryColors[category.toLowerCase()] ?? defaultCategoryColor;

  /// Soft tinted background surface for category chips and badges.
  static Color categorySurfaceFor(String category, {bool isDark = false}) {
    final base = categoryColorFor(category);
    return isDark
        ? base.withValues(alpha: 0.18)
        : base.withValues(alpha: 0.10);
  }

  /// Backward-compatible single-color gradient fallback.
  static List<Color> gradientFor(String category) {
    final color = categoryColorFor(category);
    return [color, color];
  }

  /// Backward-compatible category gradient map.
  static const categoryGradients = <String, List<Color>>{
    'road': [Color(0xFFB45309), Color(0xFFB45309)],
    'water': [Color(0xFF0284C7), Color(0xFF0284C7)],
    'power': [Color(0xFFD97706), Color(0xFFD97706)],
    'lighting': [Color(0xFF7C3AED), Color(0xFF7C3AED)],
    'waste': [Color(0xFF15803D), Color(0xFF15803D)],
    'sewage': [Color(0xFF78350F), Color(0xFF78350F)],
    'other': [Color(0xFF0F766E), Color(0xFF0F766E)],
  };

  static const defaultGradient = [Color(0xFF0F766E), Color(0xFF0F766E)];

  /// Map pin colour for a category.
  static Color pinColorFor(String category) => categoryColorFor(category);

  /// Backward-compatible dock accent color list.
  static const dockGradient = [
    Color(0xFF4F46E5),
    Color(0xFF4F46E5),
  ];
}

/// Convenience for building the brand color list reliably.
List<Color> appBrandGradient() => AppColors.brandGradient;
