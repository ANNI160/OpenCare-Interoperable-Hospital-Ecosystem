import 'package:flutter_test/flutter_test.dart';
import 'package:opencare/main.dart';

void main() {
  testWidgets('App starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenCareApp());
    expect(find.text('OpenCare'), findsOneWidget);
  });
}
