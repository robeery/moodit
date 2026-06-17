import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../model/chat_message.dart';
import '../../../theme/ai_provider_theme.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodel/editor_viewmodel.dart';
import '../../shared/app_dialog.dart';
import '../../shared/app_snack_bar.dart';

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
      showAppSnackBar(
        context,
        'AI settings are still loading. Please wait.',
        isError: true,
      );
      return;
    }
    final text = _chatController.text;
    if (text.trim().isEmpty) return;
    _chatController.clear();
    final error = await widget.vm.sendMessage(text);
    if (error != null && mounted) {
      showAppSnackBar(context, error, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.vm.messages;

    return Container(
      color: MooditColors.card,
      child: Column(
        children: [
          Expanded(
            child: messages.isEmpty && !widget.vm.isWaitingForAi
                ? Center(
                    child: Text(
                      'ASK AI ANYTHING',
                      style: MooditType.monoMeta.copyWith(
                        color: MooditColors.textOff,
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
          color: MooditColors.cardAlt,
          borderRadius: BorderRadius.circular(MooditDims.controlRadius),
          border: Border.all(color: MooditColors.hairline),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: MooditColors.textSecondary,
            strokeWidth: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final aiGradient = aiProviderGradient(widget.vm.selectedProvider);

    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            gradient: aiGradient,
            borderRadius: BorderRadius.circular(MooditDims.controlRadius),
          ),
          child: Text(
            msg.text,
            style: MooditType.bodyText.copyWith(color: MooditColors.bgInner),
          ),
        ),
      );
    }

    final bool isError = msg.isError;
    final Color bgColor =
        isError ? Colors.red.withValues(alpha: 0.1) : MooditColors.cardAlt;
    final Color borderColor =
        isError ? Colors.red.withValues(alpha: 0.3) : MooditColors.hairline;
    final Color textColor =
        isError ? Colors.red.shade300 : MooditColors.textPrimary;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(MooditDims.controlRadius),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isError) ...[
              Icon(Icons.warning_amber_rounded, color: textColor, size: 14),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                msg.text,
                style: MooditType.bodyText.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showClearChatDialog() async {
    final removesReference = widget.vm.hasAiReferenceImage;
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'CLEAR CHAT',
      message: removesReference
          ? 'This will permanently delete the saved AI conversation for this version and remove the attached reference image. The AI will lose this chat context.'
          : 'This will permanently delete the saved AI conversation for this version. The AI will lose this chat context.',
      confirmLabel: 'CLEAR',
      destructive: true,
    );
    if (confirmed) unawaited(widget.vm.clearChat());
  }

  Future<void> _showReferenceImageDialog() async {
    if (!widget.vm.canUseAiReferenceImage) return;

    final hasReference = widget.vm.hasAiReferenceImage;
    final action = await showAppChoiceDialog<_ReferenceImageAction>(
      context,
      title: hasReference ? 'REFERENCE IMAGE' : 'ATTACH REFERENCE',
      message: hasReference
          ? 'A reference image is attached and will be sent with each new AI message for this version.'
          : 'Choose a reference image from your gallery. It will be saved for this version and sent with each new AI message as visual guidance.',
      actions: [
        if (hasReference)
          const AppDialogAction(
            'DROP',
            _ReferenceImageAction.drop,
            color: MooditColors.textMuted,
          ),
        AppDialogAction(
          hasReference ? 'REPLACE' : 'CONTINUE',
          _ReferenceImageAction.pick,
        ),
      ],
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == _ReferenceImageAction.drop) {
      final removed = await widget.vm.clearAiReferenceImage();
      if (!mounted) return;
      showAppSnackBar(
        context,
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
      showAppSnackBar(context, 'Failed to attach reference image.', isError: true);
    }
  }

  Widget _buildInputArea() {
    final isOnline = widget.vm.isOnline;
    final isAiReady = widget.vm.isAiReady;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: MooditColors.hairline)),
      ),
      child: isOnline
          ? (isAiReady
              ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: aiProviderGradient(widget.vm.selectedProvider),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: widget.vm.activeAiProfileId,
                        dropdownColor: MooditColors.cardAlt,
                        borderRadius: BorderRadius.circular(MooditDims.controlRadius),
                        style: MooditType.bodySecondary,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: MooditColors.textMuted, size: 16),
                        items: widget.vm.aiProfiles.map((profile) {
                          return DropdownMenuItem(
                            value: profile.id,
                            child: Text(
                              profile.profileName,
                              overflow: TextOverflow.ellipsis,
                              style: MooditType.bodySecondary,
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
                        style: MooditType.monoMeta,
                      ),
                    ),
                    _buildReferenceImageButton(),
                    if (widget.vm.messages.isNotEmpty ||
                        widget.vm.hasAiReferenceImage)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: MooditColors.textMuted, size: 20),
                        onPressed: () => _showClearChatDialog(),
                      ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: MooditType.bodyText,
                        cursorColor: MooditColors.baseAccent,
                        decoration: InputDecoration(
                          hintText: 'Describe a mood...',
                          hintStyle: MooditType.bodySecondary.copyWith(
                            color: MooditColors.textOff,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onSubmitted: (_) => _sendChat(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _sendChat,
                      child: Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: aiProviderGradient(widget.vm.selectedProvider),
                        ),
                        child: const Icon(Icons.send, color: MooditColors.bgInner, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: MooditColors.textMuted,
                        strokeWidth: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('LOADING AI SETTINGS', style: MooditType.monoMeta),
                  ],
                ))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, color: MooditColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text('NO CONNECTION', style: MooditType.monoMeta),
              ],
            ),
    );
  }

  Widget _buildReferenceImageButton() {
    final hasReference = widget.vm.hasAiReferenceImage;
    final enabled = widget.vm.canUseAiReferenceImage;
    final color = hasReference ? MooditColors.textPrimary : MooditColors.textMuted;

    return IconButton(
      onPressed: enabled ? _showReferenceImageDialog : null,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.image_outlined, color: enabled ? color : MooditColors.textOff, size: 20),
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

enum _ReferenceImageAction { pick, drop }
