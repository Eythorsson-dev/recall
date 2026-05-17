import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recall_mobile/main.dart';

void main() {
  testWidgets('App shell renders with navigation bar', (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });
}
