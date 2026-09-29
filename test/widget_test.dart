import 'package:flutter_test/flutter_test.dart';
import 'package:anikuplay/app/app.dart';

void main() {
  testWidgets('AnikuPlayApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AnikuPlayApp());
    expect(find.text('AnikuPlay'), findsOneWidget);
  });
}
