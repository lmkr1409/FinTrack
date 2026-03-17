import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';

class MonthSwiper extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Widget child;

  const MonthSwiper({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1));
          } else if (details.primaryVelocity! > 200) {
            onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1));
          }
        }
      },
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                DateFormat('MMMM yyyy').format(currentMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
