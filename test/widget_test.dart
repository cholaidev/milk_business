import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:milk_business/main.dart';

void main() {
  testWidgets('App loads dashboard screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MilkBusinessApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsAtLeastNWidgets(1));
  });
}
