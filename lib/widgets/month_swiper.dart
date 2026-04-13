import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthSwiper extends StatelessWidget {
  final DateTime currentMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final Widget child;

  final List<Widget>? actions;

  const MonthSwiper({
    super.key,
    required this.currentMonth,
    required this.onMonthChanged,
    required this.child,
    this.actions,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(currentMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (actions != null) 
                    Theme(
                      data: Theme.of(context).copyWith(
                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      ),
                      child: Row(children: actions!),
                    ),
                ],
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
