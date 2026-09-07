import 'package:flutter/material.dart';
import '../../services/model_info_service.dart';
import '../../viewmodels/settings_viewmodel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ModelSelectorScreen extends StatefulWidget {
  final SettingsViewModel settingsViewModel;

  const ModelSelectorScreen({
    super.key,
    required this.settingsViewModel,
  });

  @override
  State<ModelSelectorScreen> createState() => _ModelSelectorScreenState();
}

class _ModelSelectorScreenState extends State<ModelSelectorScreen> {
  final ModelInfoService _modelInfoService = ModelInfoService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<ModelOption>? _availableModels;
  String? _selectedModel;
  String? _currentModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current model
      _currentModel = await _storage.read(key: 'selected_gemini_model') ??
          _modelInfoService.getDefaultModel();
      _selectedModel = _currentModel;

      // Get API key to fetch available models
      final apiKey = await widget.settingsViewModel.getApiKey();

      if (apiKey != null && apiKey.isNotEmpty) {
        // Fetch available models dynamically from API
        _availableModels = await _modelInfoService.fetchAvailableModels(apiKey);
      } else {
        // Fallback to static list if no API key
        _availableModels = _modelInfoService.getAllAvailableModels();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Fallback to static list on error
      _availableModels = _modelInfoService.getAllAvailableModels();
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSelectedModel(String modelName) async {
    await _storage.write(key: 'selected_gemini_model', value: modelName);
    setState(() {
      _currentModel = modelName;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Model changed to $modelName'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select AI Model'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availableModels == null || _availableModels!.isEmpty
              ? _buildEmptyView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header card
                    Card(
                      color: theme.colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.science,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Available Gemini Models',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Select the best model for blood report OCR and analysis',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current model indicator
                    if (_currentModel != null) ...[
                      Card(
                        color: theme.colorScheme.secondaryContainer,
                        child: ListTile(
                          leading: Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                          title: Text(
                            'Current Model',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          subtitle: Text(
                            _currentModel!,
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Model list
                    Text(
                      'Available Models (${_availableModels!.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._availableModels!.map((modelOption) {
                      final modelId = modelOption.id;
                      final displayInfo = modelOption.info;
                      final isSelected = _selectedModel == modelId;
                      final isCurrent = _currentModel == modelId;
                      final isRecommended = displayInfo.recommended;

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        color: isCurrent
                            ? theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.3)
                            : null,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedModel = modelId;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Radio<String>(
                                      value: modelId,
                                      groupValue: _selectedModel,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedModel = value;
                                          });
                                        }
                                      },
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  displayInfo.name,
                                                  style: theme
                                                      .textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              if (isRecommended)
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    'RECOMMENDED',
                                                    style: theme
                                                        .textTheme.labelSmall
                                                        ?.copyWith(
                                                      color: theme.colorScheme
                                                          .onPrimary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle,
                                                  size: 16,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Currently Active',
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 48),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        displayInfo.description,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          _buildChip(
                                              theme, '⚡ ${displayInfo.speed}'),
                                          _buildChip(theme,
                                              '⭐ ${displayInfo.quality}'),
                                          _buildChip(theme,
                                              '📊 ${displayInfo.inputTokenLimit ~/ 1000}K tokens'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
      bottomNavigationBar: _availableModels != null && _selectedModel != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FilledButton.icon(
                  onPressed: _selectedModel == _currentModel
                      ? null
                      : () async {
                          await _saveSelectedModel(_selectedModel!);
                        },
                  icon: const Icon(Icons.save),
                  label: Text(
                    _selectedModel == _currentModel
                        ? 'Already Active'
                        : 'Use This Model',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildChip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No Models Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
