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
}
