import 'package:flutter/material.dart';

class YearSwiper extends StatelessWidget {
  final int currentYear;
  final ValueChanged<int> onYearChanged;
  final Widget child;
  final List<Widget>? actions;

  const YearSwiper({
    super.key,
    required this.currentYear,
    required this.onYearChanged,
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
            onYearChanged(currentYear + 1);
          } else if (details.primaryVelocity! > 200) {
            onYearChanged(currentYear - 1);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Year $currentYear',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (actions != null) Row(children: actions!),
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
