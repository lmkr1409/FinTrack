import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/providers.dart';
import '../core/theme/app_colors.dart';

/// Displays [rawText] normally, but when demo mode is active:
/// - Shows [percentage] formatted as "X.X%" if supplied.
/// - Otherwise shows an eye-off icon inline.
class DemoValue extends ConsumerWidget {
  final String rawText;
  final double? percentage; // 0-100 scale
  final TextStyle? style;
  final Color? iconColor;

  const DemoValue({
    super.key,
    required this.rawText,
    this.percentage,
    this.style,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(demoModeProvider).valueOrNull ?? false;
    if (!isDemo) {
      return Text(rawText, style: style);
    }
    if (percentage != null) {
      return Text(
        '${percentage!.toStringAsFixed(1)}%',
        style: style,
      );
    }
    // No percentage available → eye-off icon
    final fontSize = style?.fontSize ?? 14.0;
    final color = iconColor ?? style?.color ?? AppColors.textMuted;
    return Icon(Icons.visibility_off_rounded, size: fontSize * 1.1, color: color);
  }
}
