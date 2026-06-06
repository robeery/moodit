import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendChat() async {
    if (!widget.vm.isAiReady) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'AI settings are still loading. Please wait.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
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
    final removesReference = widget.vm.hasAiReferenceImage;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: const Text('CLEAR CHAT', style: AppTextStyles.screenTitle),
        content: Text(
          removesReference
              ? 'This will permanently delete the saved AI conversation for this version and remove the attached reference image. The AI will lose this chat context.'
              : 'This will permanently delete the saved AI conversation for this version. The AI will lose this chat context.',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
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
              unawaited(widget.vm.clearChat());
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

  Future<void> _showReferenceImageDialog() async {
    if (!widget.vm.canUseAiReferenceImage) return;

    final hasReference = widget.vm.hasAiReferenceImage;
    final action = await showDialog<_ReferenceImageAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        title: Text(
          hasReference ? 'REFERENCE IMAGE' : 'ATTACH REFERENCE',
          style: AppTextStyles.screenTitle,
        ),
        content: Text(
          hasReference
              ? 'A reference image is attached and will be sent with each new AI message for this version.'
              : 'Choose a reference image from your gallery. It will be saved for this version and sent with each new AI message as visual guidance.',
          style: const TextStyle(color: AppColors.accent, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ReferenceImageAction.cancel),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
            ),
          ),
          if (hasReference)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(_ReferenceImageAction.drop),
              child: const Text(
                'DROP',
                style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 2),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(_ReferenceImageAction.pick),
            child: Text(
              hasReference ? 'REPLACE' : 'CONTINUE',
              style: const TextStyle(color: AppColors.highlight, fontSize: 11, letterSpacing: 2),
            ),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == _ReferenceImageAction.cancel) {
      return;
    }

    if (action == _ReferenceImageAction.drop) {
      final removed = await widget.vm.clearAiReferenceImage();
      if (!mounted) return;
      _showReferenceSnack(
        removed ? 'Reference image removed.' : 'Failed to remove reference image.',
        isError: !removed,
      );
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted || picked == null) return;

    final attached = await widget.vm.attachAiReferenceImage(picked.path);
    if (!mounted) return;
    if (!attached) {
      _showReferenceSnack(
        'Failed to attach reference image.',
        isError: true,
      );
    }
  }

  void _showReferenceSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : AppColors.surface,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildInputArea() {
    final isOnline = widget.vm.isOnline;
    final isAiReady = widget.vm.isAiReady;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.muted, width: 0.5)),
      ),
      child: isOnline
          ? (isAiReady
              ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.account_circle_outlined,
                      color: AppColors.muted,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: DropdownButton<String>(
                        value: widget.vm.activeAiProfileId,
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: AppColors.accent, fontSize: 11),
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.muted, size: 16),
                        items: widget.vm.aiProfiles.map((profile) {
                          return DropdownMenuItem(
                            value: profile.id,
                            child: Text(
                              profile.profileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            unawaited(widget.vm.setActiveAiProfile(value));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        widget.vm.selectedModel,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    _buildReferenceImageButton(),
                    if (widget.vm.messages.isNotEmpty ||
                        widget.vm.hasAiReferenceImage)
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
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: AppColors.muted,
                        strokeWidth: 1.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'LOADING AI SETTINGS',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ))
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

  Widget _buildReferenceImageButton() {
    final hasReference = widget.vm.hasAiReferenceImage;
    final enabled = widget.vm.canUseAiReferenceImage;
    final color = hasReference ? AppColors.highlight : AppColors.muted;

    return IconButton(
      onPressed: enabled ? _showReferenceImageDialog : null,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.image_outlined, color: enabled ? color : AppColors.muted, size: 20),
          if (hasReference)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: aiProviderGradient(widget.vm.selectedProvider),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _ReferenceImageAction { cancel, pick, drop }
