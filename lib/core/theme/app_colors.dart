import 'package:flutter/material.dart';

/// FinTrack color palette — "High-Contrast Fintech Dark"
/// Based on Tailwind Slate, Cyan, Emerald, Fuchsia, and Lime.
///
/// 60-30-10 Rule:
///   60% — Deep neutral backgrounds (Slate 950/900)
///   30% — Charcoal containers & cards (Slate 800/850)
///   10% — Vibrant neon accents (Cyan, Lime, Fuchsia)
class AppColors {
  AppColors._();

  // ─── 60% — Deep neutral backgrounds ────────────────────
  static const Color background      = Color(0xFF0B1120); // Slate 950 tweaked
  static const Color surface         = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDim      = Color(0xFF080E1C); // Deeper than 950

  // ─── 30% — Charcoal containers / cards ─────────────────
  static const Color cardBackground  = Color(0xFF1E293B); // Slate 800
  static const Color cardElevated    = Color(0xFF253346); // Between 800-700
  static const Color surfaceContainer = Color(0xFF1A2332); // Slightly lighter

  // ─── 10% — Vibrant neon accents ─────────────────────────
  static const Color primary         = Color(0xFF22D3EE); // Cyan 400
  static const Color primaryDark     = Color(0xFF06B6D4); // Cyan 500
  static const Color secondary       = Color(0xFFD946EF); // Fuchsia 500
  static const Color tertiary        = Color(0xFFA3E635); // Lime 400

  // ─── Gradient pair for header ───────────────────────────
  static const Color gradientStart   = Color(0xFF06B6D4); // Cyan 500
  static const Color gradientEnd     = Color(0xFFD946EF); // Fuchsia 500

  // ─── Functional colors (WCAG 4.5:1 against Slate 900/800)
  static const Color income          = Color(0xFF34D399); // Emerald 400  — contrast ~10:1
  static const Color expense         = Color(0xFFFB7185); // Rose 400     — contrast ~6.5:1
  static const Color warning         = Color(0xFFFBBF24); // Amber 400
  static const Color info            = Color(0xFF38BDF8); // Sky 400


  // ─── Text hierarchy ─────────────────────────────────────
  static const Color textPrimary     = Color(0xFFF1F5F9); // Slate 100
  static const Color textSecondary   = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted       = Color(0xFF64748B); // Slate 500

  // ─── Borders / dividers ─────────────────────────────────
  static const Color border          = Color(0xFF334155); // Slate 700
  static const Color borderSubtle    = Color(0xFF1E293B); // Slate 800
  static const Color glassBorder     = Color(0x80475569); // Slate 600 @ 50%

  // ─── Navigation ─────────────────────────────────────────
  static const Color navBackground   = Color(0xFF0F172A); // Slate 900
  static const Color navIndicator    = Color(0x3322D3EE); // Cyan 400 @ 20%
}
