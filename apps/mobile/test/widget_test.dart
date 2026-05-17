import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:core/core.dart';
import 'package:drift/native.dart';

import 'package:recall_mobile/main.dart';

void main() {
  setUp(() {
    database = RecallDatabase(NativeDatabase.memory());
    cardRepository = CardRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  testWidgets('App shell renders with navigation bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));
  });

  testWidgets('Home screen shows due card count', (WidgetTester tester) async {
    await tester.pumpWidget(const RecallApp());
    await tester.pumpAndSettle();

    expect(find.text('0 cards due today'), findsOneWidget);
  });

  testWidgets('Home screen updates after creating a card',
      (WidgetTester tester) async {
    await cardRepository.createCard(
      language: 'Ukrainian',
      fields: {'Ukrainian': 'привіт', 'English': 'hello'},
      fieldSpeakable: {'Ukrainian': true, 'English': false},
    );

    await tester.pumpWidget(const RecallApp());
    await tester.pumpAndSettle();

    expect(find.text('1 cards due today'), findsOneWidget);
  });

  testWidgets('Study session shows direction picker',
      (WidgetTester tester) async {
    await cardRepository.createCard(
      language: 'Ukrainian',
      fields: {'Ukrainian': 'привіт', 'English': 'hello'},
      fieldSpeakable: {'Ukrainian': true, 'English': false},
    );

    await tester.pumpWidget(const RecallApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Study Session'));
    await tester.pumpAndSettle();

    expect(find.text('Study Session'), findsOneWidget);
    expect(find.text('Source → Target'), findsOneWidget);
    expect(find.text('Target → Source'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('Listening with Text'), findsOneWidget);
    expect(find.text('Listening without Text'), findsOneWidget);
  });
}
