import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import 'glass_card.dart';

class MonthSwiper extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const MonthSwiper({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
  });

  void _previousMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month - 1));
  }

  void _nextMonth() {
    onMonthChanged(DateTime(currentMonth.year, currentMonth.month + 1));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Swipe left -> Next month
        if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
          _nextMonth();
        }
        // Swipe right -> Previous month
        else if (details.primaryVelocity != null && details.primaryVelocity! > 0) {
          _previousMonth();
        }
      },
      child: GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primary),
              onPressed: _previousMonth,
            ),
            Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
              onPressed: _nextMonth,
            ),
          ],
        ),
      ),
    );
  }
}
