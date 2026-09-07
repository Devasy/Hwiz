import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../utils/page_transitions.dart';
import 'model_selector_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.key,
                                color: theme.colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gemini API Key',
                                      style:
                                          theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Required for blood report analysis',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // API Key Status
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: viewModel.hasApiKey
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  viewModel.hasApiKey
                                      ? Icons.check_circle
                                      : Icons.error_outline,
                                  color: viewModel.hasApiKey
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        viewModel.hasApiKey
                                            ? 'API Key Configured'
                                            : 'No API Key',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          color: viewModel.hasApiKey
                                              ? theme.colorScheme
                                                  .onPrimaryContainer
                                              : theme
                                                  .colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (viewModel.hasApiKey) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          viewModel.maskedApiKey,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Messages
                  if (viewModel.errorMessage != null) ...[
                    _MessageCard(
                      message: viewModel.errorMessage!,
                      isError: true,
                      onDismiss: () => viewModel.clearMessages(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (viewModel.successMessage != null) ...[
                    _MessageCard(
                      message: viewModel.successMessage!,
                      isError: false,
                      onDismiss: () => viewModel.clearMessages(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Action Buttons
                  if (viewModel.hasApiKey) ...[
                    _UpdateApiKeyButton(viewModel: viewModel),
                    const SizedBox(height: 12),
                    _SelectModelButton(viewModel: viewModel),
                    const SizedBox(height: 12),
                    _DeleteApiKeyButton(viewModel: viewModel),
                  ] else ...[
                    _AddApiKeyButton(viewModel: viewModel),
                  ],

                  const SizedBox(height: 24),

                  // Instructions Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'How to get an API key',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InstructionStep(
                            number: 1,
                            text: 'Visit Google AI Studio',
                            action: 'Open Link',
                            onTap: () => _launchUrl(
                                'https://makersuite.google.com/app/apikey'),
                          ),
                          const SizedBox(height: 8),
                          _InstructionStep(
                            number: 2,
                            text: 'Sign in with your Google account',
                          ),
                          const SizedBox(height: 8),
                          _InstructionStep(
                            number: 3,
                            text: 'Click "Get API Key" or "Create API Key"',
                          ),
                          const SizedBox(height: 8),
                          _InstructionStep(
                            number: 4,
                            text: 'Copy the generated API key',
                          ),
                          const SizedBox(height: 8),
                          _InstructionStep(
                            number: 5,
                            text: 'Paste it in the app and save',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _launchUrl(String url) {
    // TODO: Implement URL launcher when needed
    // For now, users can manually visit the URL
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _MessageCard({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isError
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? theme.colorScheme.onErrorContainer
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: isError
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onPrimaryContainer,
              ),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddApiKeyButton extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _AddApiKeyButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: viewModel.isValidating
            ? null
            : () => _showApiKeyDialog(context, viewModel, isUpdate: false),
        icon: const Icon(Icons.add),
        label: const Text('Add API Key'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _UpdateApiKeyButton extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _UpdateApiKeyButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: viewModel.isValidating
            ? null
            : () => _showApiKeyDialog(context, viewModel, isUpdate: true),
        icon: const Icon(Icons.edit),
        label: const Text('Update API Key'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _SelectModelButton extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _SelectModelButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () {
          context.pushVertical(
            ModelSelectorScreen(
              settingsViewModel: viewModel,
            ),
          );
        },
        icon: const Icon(Icons.tune),
        label: const Text('Select AI Model'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _DeleteApiKeyButton extends StatelessWidget {
  final SettingsViewModel viewModel;

  const _DeleteApiKeyButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: viewModel.isLoading
            ? null
            : () => _showDeleteConfirmation(context, viewModel),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Delete API Key'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String text;
  final String? action;
  final VoidCallback? onTap;

  const _InstructionStep({
    required this.number,
    required this.text,
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text),
              if (action != null && onTap != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(action!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

void _showApiKeyDialog(BuildContext context, SettingsViewModel viewModel,
    {required bool isUpdate}) {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isValidating = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(isUpdate ? 'Update API Key' : 'Add API Key'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your Google Gemini API key:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'AIza...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an API key';
                    }
                    if (!value.startsWith('AIza')) {
                      return 'Invalid format. Should start with "AIza"';
                    }
                    return null;
                  },
                  maxLines: 2,
                  keyboardType: TextInputType.visiblePassword,
                ),
                const SizedBox(height: 8),
                Text(
                  'The key will be validated before saving',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isValidating ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: isValidating
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        setState(() => isValidating = true);

                        final success =
                            await viewModel.saveApiKey(controller.text.trim());

                        setState(() => isValidating = false);

                        if (success && context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
              icon: isValidating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(isValidating ? 'Validating...' : 'Save'),
            ),
          ],
        );
      },
    ),
  );
}

void _showDeleteConfirmation(
    BuildContext context, SettingsViewModel viewModel) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete API Key?'),
      content: const Text(
        'Are you sure you want to delete your API key? '
        'You will need to add it again to use the blood report analysis feature.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await viewModel.deleteApiKey();
            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
