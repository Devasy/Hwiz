// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:lablens/main.dart';
import 'package:lablens/widgets/navigation/m3_floating_nav_bar.dart';

void main() {
  testWidgets('LabLens app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LabLensApp());

    // Verify that the app starts without crashing
    await tester.pumpAndSettle();

    // The app should have M3FloatingNavBar navigation
    expect(find.byType(M3FloatingNavBar), findsOneWidget);

    // Should have Home tab label visible (active tab)
    expect(find.text('Home'), findsOneWidget);
  });
}
