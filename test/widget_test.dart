import 'package:flutter_test/flutter_test.dart';
import 'package:jarvis_ai/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('JARVIS main app boots with navigation shell', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JarvisApp());
    expect(find.text('J A R V I S'), findsOneWidget);
  });
}
