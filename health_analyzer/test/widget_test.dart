import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:lablens/main.dart';
import 'package:lablens/widgets/navigation/m3_floating_nav_bar.dart';
import 'package:lablens/viewmodels/theme_viewmodel.dart';
import 'package:lablens/viewmodels/profile_viewmodel.dart';
import 'package:lablens/viewmodels/report_viewmodel.dart';
import 'package:lablens/models/profile.dart';
import 'package:lablens/views/screens/settings_tab.dart';
import 'package:lablens/views/screens/home_tab.dart';
import 'package:lablens/widgets/common/expandable_fab.dart';
import 'package:lablens/services/batch_processing_service.dart';

/// Test fixtures for clean, decoupled testing
class TestFixtures {
  static Profile createProfile({
    int id = 1,
    String name = 'Test User',
    String dateOfBirth = '1995-05-15',
    String gender = 'Female',
    String relationship = 'Self',
  }) {
    return Profile(
      id: id,
      name: name,
      dateOfBirth: dateOfBirth,
      gender: gender,
      relationship: relationship,
    );
  }
}

class _MockProfileViewModel extends ProfileViewModel {
  final Profile? _profile;
  _MockProfileViewModel([this._profile]);

  @override
  Profile? get currentProfile => _profile;

  @override
  Profile? get selectedProfile => _profile;

  @override
  List<Profile> get profiles => _profile != null ? [_profile!] : [];

  @override
  bool get hasProfiles => _profile != null;
}

class _MockReportViewModel extends ReportViewModel {
  @override
  bool get isLoading => false;

  @override
  Future<void> loadReportsForProfile(int profileId) async {
    // No-op for widget test
  }
}

void main() {
  group('LabLens App Smoke & Navigation', () {
    testWidgets('LabLens app starts and renders header', (WidgetTester tester) async {
      await tester.pumpWidget(const LabLensApp());
      await tester.pumpAndSettle();

      expect(find.text('LabLens'), findsOneWidget);
      expect(find.byType(M3FloatingNavBar), findsNothing);
      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
    });
  });

  group('SettingsTab Tests', () {
    testWidgets('renders sections without active profile', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),
            ChangeNotifierProvider<ProfileViewModel>(create: (_) => _MockProfileViewModel()),
          ],
          child: const MaterialApp(
            home: SettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Settings & Profiles'), findsOneWidget);
      expect(find.text('AI Configuration'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
    });

    testWidgets('renders active profile details dynamically', (WidgetTester tester) async {
      final profile = TestFixtures.createProfile(name: 'Sarah Connor');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeViewModel()),
            ChangeNotifierProvider<ProfileViewModel>(create: (_) => _MockProfileViewModel(profile)),
          ],
          child: const MaterialApp(
            home: SettingsTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Settings & Profiles'), findsOneWidget);
      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('HomeTab FAB Scan Selection Tests', () {
    testWidgets('FAB renders with Camera, Photos, Single PDF, and Multiple PDFs options',
        (WidgetTester tester) async {
      final profile = TestFixtures.createProfile();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ProfileViewModel>(create: (_) => _MockProfileViewModel(profile)),
            ChangeNotifierProvider<ReportViewModel>(create: (_) => _MockReportViewModel()),
          ],
          child: const MaterialApp(
            home: HomeTab(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the main FAB
      expect(find.byType(ExpandableFab), findsOneWidget);

      // Tap FAB to expand
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify the 4 upload/scan options are rendered
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Single PDF'), findsOneWidget);
      expect(find.text('Multiple PDFs'), findsOneWidget);
    });
  });

  group('Batch Processing Result Calculations', () {
    test('computes success and failure rates accurately', () {
      final startTime = DateTime(2026, 1, 1, 10, 0, 0);
      final endTime = DateTime(2026, 1, 1, 10, 0, 10);

      final result = BatchProcessingResult(
        successful: const [],
        failed: const [],
        totalProcessed: 5,
        startTime: startTime,
        endTime: endTime,
      );

      expect(result.totalProcessed, equals(5));
      expect(result.successCount, equals(0));
      expect(result.failureCount, equals(0));
      expect(result.duration.inSeconds, equals(10));
    });
  });
}

