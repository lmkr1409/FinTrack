import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A glassmorphic card with [BackdropFilter] blur, subtle border (0.5 width),
/// and a translucent background.
///
/// Usage:
/// ```dart
/// GlassCard(child: ListTile(...))
/// ```
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.borderRadius = 16,
    this.blurSigma = 12,
    this.borderWidth = 0.5,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.cardBackground.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
