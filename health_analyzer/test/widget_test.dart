// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lablens/main.dart';
import 'package:lablens/widgets/navigation/m3_floating_nav_bar.dart';

void main() {
  testWidgets('LabLens app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LabLensApp());

    // Verify that the app starts without crashing
    await tester.pumpAndSettle();

    // The app should render LabLens brand title on top
    expect(find.text('LabLens'), findsOneWidget);

    // Should NOT have bottom navigation bar (streamlined full-screen UX)
    expect(find.byType(M3FloatingNavBar), findsNothing);

    // Top action bar has Ask AI button
    expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
  });
}

