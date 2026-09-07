// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lablens/main.dart';
import 'package:lablens/widgets/navigation/m3_floating_nav_bar.dart';
import 'package:lablens/viewmodels/theme_viewmodel.dart';
import 'package:lablens/viewmodels/profile_viewmodel.dart';
import 'package:lablens/models/profile.dart';
import 'package:lablens/views/screens/settings_tab.dart';

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

  testWidgets('SettingsTab renders without errors', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeViewModel()),
          ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ],
        child: const MaterialApp(
          home: SettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Settings & Profiles'), findsOneWidget);
    expect(find.text('Active Profile & Family'), findsOneWidget);
    expect(find.text('AI Configuration'), findsOneWidget);
    expect(find.text('Appearance & Theme'), findsOneWidget);
  });

  testWidgets('SettingsTab renders with an active profile without NoSuchMethodError', (WidgetTester tester) async {
    final fakeProfile = Profile(
      id: 1,
      name: 'John Doe',
      dateOfBirth: '1990-01-01',
      gender: 'Male',
      relationship: 'Self',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeViewModel()),
          ChangeNotifierProvider<ProfileViewModel>(create: (_) => _FakeProfileViewModel(fakeProfile)),
        ],
        child: const MaterialApp(
          home: SettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Settings & Profiles'), findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });
}

class _FakeProfileViewModel extends ProfileViewModel {
  final Profile _mockProfile;
  _FakeProfileViewModel(this._mockProfile);

  @override
  Profile? get currentProfile => _mockProfile;

  @override
  Profile? get selectedProfile => _mockProfile;

  @override
  List<Profile> get profiles => [_mockProfile];

  @override
  bool get hasProfiles => true;
}

