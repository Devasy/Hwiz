import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/theme_extensions.dart';
import '../../../viewmodels/settings_viewmodel.dart';
import '../../../widgets/common/app_button.dart';
import 'first_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

/// API key setup screen
class ApiSetupScreen extends StatefulWidget {
  const ApiSetupScreen({super.key});

  @override
  State<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends State<ApiSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  bool _isObscured = true;
  bool _isTesting = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchHelp() async {
    final url = Uri.parse('https://aistudio.google.com/app/apikey');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    final settingsVM = context.read<SettingsViewModel>();

    try {
      // Save and validate API key
      final success =
          await settingsVM.saveApiKey(_apiKeyController.text.trim());

      if (mounted) {
        if (success) {
          // Navigate to first profile creation
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FirstProfileScreen(),
            ),
          );
        } else {
          // Show error from ViewModel
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(settingsVM.errorMessage ?? 'Invalid API key')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surfaceColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: context.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.key,
                    size: 50,
                    color: context.primaryColor,
                  ),
                ),

                const SizedBox(height: AppTheme.spacing32),

                // Title
                Text(
                  'Connect Your AI Engine',
                  style: AppTheme.headingLarge,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacing16),

                // Description
                Text(
                  'To analyze your blood reports, LabLens needs a Google Gemini API key. Your key stays on your device - we never store it.',
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppTheme.spacing40),

                // API Key input
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key',
                    hintText: 'Enter your API key',
                    prefixIcon: const Icon(Icons.vpn_key),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your API key';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppTheme.spacing16),

                // Help link
                TextButton.icon(
                  onPressed: _launchHelp,
                  icon: const Icon(Icons.help_outline),
                  label: const Text('How to get an API key?'),
                ),

                const SizedBox(height: AppTheme.spacing16),

                // Info card
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacing16),
                  decoration: BoxDecoration(
                    color: AppTheme.infoLight,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppTheme.infoColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppTheme.spacing8),
                          Text(
                            'Privacy & Security',
                            style: AppTheme.titleSmall.copyWith(
                              color: AppTheme.infoColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacing8),
                      Text(
                        '• Your API key is stored locally on your device\n'
                        '• Reports are analyzed securely using Google Gemini\n'
                        '• No data is stored on our servers\n'
                        '• You can change your key anytime in Settings',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.infoColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.spacing40),

                // Continue button
                AppButton(
                  text: 'Continue',
                  onPressed: _saveAndContinue,
                  isLoading: _isTesting,
                  width: double.infinity,
                ),

                const SizedBox(height: AppTheme.spacing16),

                // Skip button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const FirstProfileScreen(),
                      ),
                    );
                  },
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
