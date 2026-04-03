import 'package:flutter/material.dart';
import '../../../model/chat_message.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';

class ChatPanel extends StatefulWidget {
  final EditorViewModel vm;

  const ChatPanel({super.key, required this.vm});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _chatController = TextEditingController();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    final text = _chatController.text;
    if (text.trim().isEmpty) return;
    _chatController.clear();
    final error = await widget.vm.sendMessage(text);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.vm.messages;

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(
            child: messages.isEmpty && !widget.vm.isWaitingForAi
                ? const Center(
                    child: Text(
                      'ASK AI ANYTHING',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        letterSpacing: 3,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: messages.length + (widget.vm.isWaitingForAi ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildLoadingBubble();
                      }
                      final msg = messages[index];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.muted, width: 0.5),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    switch (msg.type) {
      case MessageType.user:
        bgColor = AppColors.highlight.withValues(alpha: 0.15);
        borderColor = AppColors.highlight.withValues(alpha: 0.3);
        textColor = AppColors.highlight;
      case MessageType.ai:
        bgColor = AppColors.bg;
        borderColor = AppColors.muted;
        textColor = AppColors.accent;
      case MessageType.error:
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red.withValues(alpha: 0.3);
        textColor = Colors.red.shade300;
    }

    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (msg.isError) ...[
              Icon(Icons.warning_amber_rounded, color: textColor, size: 14),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                msg.text,
                style: TextStyle(color: textColor, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('CLEAR CHAT', style: AppTextStyles.screenTitle),
        content: const Text(
          'This will permanently delete the conversation. The AI will lose all context from this session.',
          style: TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.vm.clearChat();
            },
            child: const Text(
              'CLEAR',
              style: TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    final isOnline = widget.vm.isOnline;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.muted, width: 0.5)),
      ),
      child: isOnline
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'MODEL ',
                      style: TextStyle(color: AppColors.muted, fontSize: 9, letterSpacing: 2),
                    ),
                    DropdownButton<String>(
                      value: widget.vm.selectedModel,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.accent, fontSize: 11),
                      underline: const SizedBox.shrink(),
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.muted, size: 16),
                      items: widget.vm.availableModels.map((model) {
                        return DropdownMenuItem(
                          value: model,
                          child: Text(model, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) widget.vm.setSelectedModel(value);
                      },
                    ),
                    const Spacer(),
                    if (widget.vm.messages.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.muted, size: 20),
                        onPressed: () => _showClearChatDialog(),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: const TextStyle(color: AppColors.highlight, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: AppColors.muted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.accent, size: 20),
                      onPressed: _sendChat,
                    ),
                  ],
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, color: AppColors.muted, size: 16),
                SizedBox(width: 8),
                Text(
                  'NO CONNECTION',
                  style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
                ),
              ],
            ),
    );
  }
}
