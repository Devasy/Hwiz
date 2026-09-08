import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Chat History',
            onPressed: () => _showHistorySheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New Chat',
            onPressed: () {
              context.read<AskAiViewModel>().startNewConversation();
              _textController.clear();
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
                  child: isUser
                      ? SelectableText(
                          text,
                          style: TextStyle(
                            color: fg,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        )
                      : MarkdownBody(
                          data: text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                            p: TextStyle(
                              color: fg,
                              fontSize: 15,
                              height: 1.45,
                            ),
                            strong: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            h1: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 15,
                            ),
                            code: TextStyle(
                              backgroundColor: colorScheme.surfaceContainerLow,
                              color: colorScheme.onSurfaceVariant,
                              fontFamily: 'monospace',
                              fontSize: 13,
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            tableBorder: TableBorder.all(
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            tableHead: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            tableBody: TextStyle(
                              color: fg,
                              fontSize: 13,
                            ),
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

  void _showHistorySheet(BuildContext context) {
    final vm = context.read<AskAiViewModel>();
    final profile = context.read<ProfileViewModel>().currentProfile;
    vm.loadSessions(profileId: profile?.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.history_rounded, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Chat History',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const Spacer(),
                      Consumer<AskAiViewModel>(
                        builder: (_, askVM, __) {
                          if (askVM.sessions.isEmpty) return const SizedBox.shrink();
                          return TextButton.icon(
                            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                            label: const Text('Clear All'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.error,
                            ),
                            onPressed: () => _confirmClearAllSessions(context),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // New conversation quick action
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(Icons.add, color: colorScheme.onPrimaryContainer),
                  ),
                  title: const Text('Start New Conversation'),
                  subtitle: const Text('Clear active chat & start fresh'),
                  onTap: () {
                    vm.startNewConversation();
                    _textController.clear();
                    Navigator.pop(sheetContext);
                  },
                ),

                const Divider(height: 1),

                // Session list
                Expanded(
                  child: Consumer<AskAiViewModel>(
                    builder: (_, askVM, __) {
                      if (askVM.sessions.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 48,
                                color: colorScheme.outlineVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No chat history yet',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Your past conversations will appear here',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: askVM.sessions.length,
                        itemBuilder: (ctx, i) {
                          final session = askVM.sessions[i];
                          final isActive = session.id == askVM.currentSessionId;

                          return ListTile(
                            selected: isActive,
                            selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: isActive
                                  ? colorScheme.primary
                                  : colorScheme.surfaceContainerHigh,
                              child: Icon(
                                Icons.auto_awesome,
                                size: 18,
                                color: isActive
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            title: Text(
                              session.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${session.messageCount} msg${session.messageCount == 1 ? '' : 's'} • ${_formatDate(session.updatedAt)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              tooltip: 'Delete Chat',
                              onPressed: () => askVM.deleteSession(session.id!),
                            ),
                            onTap: () {
                              askVM.restoreSession(session.id!);
                              Navigator.pop(sheetContext);
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Loaded "${session.title}"'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) {
      return diff.inMinutes <= 1 ? 'Just now' : '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  void _confirmClearAllSessions(BuildContext context) {
    final vm = context.read<AskAiViewModel>();
    final profile = context.read<ProfileViewModel>().currentProfile;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Chat History?'),
        content: const Text(
          'This will permanently delete all saved AI conversation sessions for this profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              vm.deleteAllSessions(profileId: profile?.id);
              Navigator.pop(dialogCtx);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }
}
