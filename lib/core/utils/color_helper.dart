import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Utility to convert a hex color string stored in the database
/// into a Flutter [Color] instance.
///
/// Usage:
/// ```dart
/// final color = ColorHelper.fromHex('#FF9800');
/// ```
class ColorHelper {
  ColorHelper._();

  /// Parses a hex color string (e.g. '#FF9800' or 'FF9800') into a [Color].
  /// Returns [fallback] if the string is null or invalid.
  static Color fromHex(String? hex, {Color fallback = Colors.grey}) {
    if (hex == null || hex.isEmpty) return fallback;
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // add full opacity
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  /// Converts a Flutter [Color] into a hex string, e.g. '#FF9800'.
  static String toHex(Color color) {
    return '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Generates a visually distinct hex color string that does not exist in [existingColors].
  static String generateUniqueColor(List<String> existingColors) {
    final rand = math.Random();
    const materialPalette = [
      '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5',
      '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50',
      '#8BC34A', '#CDDC39', '#FFEB3B', '#FFC107', '#FF9800',
      '#FF5722', '#795548', '#9E9E9E', '#607D8B'
    ];
    
    // Normalize existing colors to uppercase with #
    final normalizedExisting = existingColors.map((c) => c.toUpperCase().startsWith('#') ? c.toUpperCase() : '#${c.toUpperCase()}').toSet();

    // Shuffle preset palette and pick the first unused one
    final shuffled = List<String>.from(materialPalette)..shuffle(rand);
    for (final c in shuffled) {
      if (!normalizedExisting.contains(c)) return c;
    }
    
    // Fallback: Generate completely random non-grey color
    int r = rand.nextInt(200) + 20; // avoid too dark/too light
    int g = rand.nextInt(200) + 20;
    int b = rand.nextInt(200) + 20;
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }
}
