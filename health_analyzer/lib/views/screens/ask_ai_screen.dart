import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ask_ai_viewmodel.dart';
import '../../viewmodels/profile_viewmodel.dart';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(AskAiViewModel vm, ProfileViewModel profileVM) {
    final text = _textController.text.trim();
    if (text.isEmpty || vm.isLoading) return;

    final profile = profileVM.currentProfile;
    _textController.clear();
    HapticFeedback.lightImpact();

    vm.sendMessage(
      text,
      activeProfileName: profile?.name,
      activeProfileId: profile?.id,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileVM = context.watch<ProfileViewModel>();
    final currentProfile = profileVM.currentProfile;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Ask AI', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (currentProfile != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Chip(
                avatar: const Icon(Icons.person, size: 16),
                label: Text(
                  currentProfile.name.split(' ')[0],
                  style: const TextStyle(fontSize: 12),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
            onPressed: () {
              context.read<AskAiViewModel>().clearConversation();
            },
          ),
        ],
      ),
      body: Consumer<AskAiViewModel>(
        builder: (context, vm, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.isLoading) _scrollToBottom();
          });

          return Column(
            children: [
              // Message list or empty state
              Expanded(
                child: vm.messages.isEmpty && vm.streamingText.isEmpty
                    ? _buildEmptyState(context, vm, profileVM)
                    : _buildMessageList(context, vm),
              ),

              // Active SQL Tool Indicator
              if (vm.activeToolQuery != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Querying health database via SQL...',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Bottom Input Bar
              _buildInputBar(context, vm, profileVM),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AskAiViewModel vm,
    ProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final profileName = profileVM.currentProfile?.name ?? 'your family';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Health Analytics Assistant',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Ask questions about test values, compare reports across dates, and check abnormal parameters for $profileName.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'SUGGESTED QUESTIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...AskAiViewModel.suggestions.map((suggestion) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    _textController.text = suggestion;
                    _handleSend(vm, profileVM);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.bolt, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(color: colorScheme.onSurface),
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
    );
  }

  Widget _buildMessageList(BuildContext context, AskAiViewModel vm) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: vm.messages.length + (vm.streamingText.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == vm.messages.length && vm.streamingText.isNotEmpty) {
          // Streaming message turn
          return _buildBubble(
            context,
            text: vm.streamingText,
            isUser: false,
            isStreaming: true,
          );
        }

        final msg = vm.messages[index];
        return _buildBubble(
          context,
          text: msg.text,
          isUser: msg.role == 'user',
          executedQuery: msg.executedQuery,
        );
      },
    );
  }

  Widget _buildBubble(
    BuildContext context, {
    required String text,
    required bool isUser,
    bool isStreaming = false,
    String? executedQuery,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bg = isUser
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(Icons.auto_awesome, size: 16, color: colorScheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (executedQuery != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.terminal, size: 14, color: colorScheme.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'Queried SQLite Database',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                    ),
                  ),
                  child: SelectableText(
                    text,
                    style: TextStyle(
                      color: fg,
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ),
                if (isStreaming)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Analyzing...',
                      style: TextStyle(fontSize: 11, color: colorScheme.outline),
                    ),
                  ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputBar(
    BuildContext context,
    AskAiViewModel vm,
    ProfileViewModel profileVM,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ask about your blood reports...',
                hintStyle: TextStyle(color: colorScheme.outline),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _handleSend(vm, profileVM),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: vm.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            onPressed: vm.isLoading ? null : () => _handleSend(vm, profileVM),
          ),
        ],
      ),
    );
  }
}
