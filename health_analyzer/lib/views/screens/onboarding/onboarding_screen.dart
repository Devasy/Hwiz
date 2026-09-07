import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_extensions.dart';
import 'api_setup_screen.dart';

/// Welcome screen with carousel
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.document_scanner,
      title: 'Scan Reports',
      description:
          'Quickly scan your blood reports using your phone camera or upload PDFs',
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      icon: Icons.analytics_outlined,
      title: 'Extract Data',
      description:
          'AI automatically extracts and organizes all parameters from your reports',
      color: AppTheme.accentColor,
    ),
    OnboardingPage(
      icon: Icons.trending_up,
      title: 'Track Trends',
      description: 'Monitor health trends over time for your entire family',
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      icon: Icons.insights,
      title: 'Get Insights',
      description: 'Receive AI-powered health insights and recommendations',
      color: AppTheme.successColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToApiSetup();
    }
  }

  void _skip() {
    _navigateToApiSetup();
  }

  void _navigateToApiSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const ApiSetupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skip,
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Logo
            const SizedBox(height: AppTheme.spacing24),
            Text(
              'LabLens',
              style: AppTheme.headingLarge.copyWith(
                color: context.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 36,
              ),
            ),

            const SizedBox(height: AppTheme.spacing8),
            Text(
              'Your Family\'s Health, Tracked & Analyzed',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Page indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),

            const SizedBox(height: AppTheme.spacing32),

            // Navigation buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.spacing24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0)
                    const SizedBox(width: AppTheme.spacing16),
                  Expanded(
                    flex: _currentPage > 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing32),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 80,
              color: page.color,
            ),
          ),

          const SizedBox(height: AppTheme.spacing40),

          // Title
          Text(
            page.title,
            style: AppTheme.headingMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppTheme.spacing16),

          // Description
          Text(
            page.description,
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return Builder(
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 8,
        width: isActive ? 24 : 8,
        decoration: BoxDecoration(
          color: isActive ? context.primaryColor : AppTheme.dividerColor,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
