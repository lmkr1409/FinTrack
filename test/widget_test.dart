import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fintrack/main.dart';

void main() {
  testWidgets('FinTrack app smoke test', (WidgetTester tester) async {
    // Build the app wrapped in ProviderScope (required for Riverpod).
    await tester.pumpWidget(
      const ProviderScope(child: FinTrackApp()),
    );

    // Verify the FinTrack title is displayed.
    expect(find.text('FinTrack'), findsWidgets);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
  });
}
