import 'package:flutter_test/flutter_test.dart';
import 'package:recall_desktop/main.dart';

void main() {
  testWidgets('Desktop app renders', (WidgetTester tester) async {
    await tester.pumpWidget(const RecallDesktopApp());

    expect(find.text('Recall Desktop'), findsOneWidget);
  });
}
