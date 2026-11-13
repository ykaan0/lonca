import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/models.dart';
import '../../services/db.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/ui.dart';

/// Grup ekranında sağdan içe girip çıkabilen yan sohbet paneli.
class ChatPanel extends StatefulWidget {
  final Group group;
  const ChatPanel({super.key, required this.group});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _ctrl = TextEditingController();
  late final Stream<List<ChatMessage>> _stream = Db.messagesStream(widget.group.id);
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(AppUser me) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    _ctrl.clear();
    setState(() => _sending = true);
    await guard(context, () => Db.sendMessage(widget.group.id, me, text));
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final me = UserScope.maybeMe(context);
    if (me == null) return const SizedBox.shrink();
    final muted = widget.group.isMuted(me.uid);
    final width = math.min(MediaQuery.sizeOf(context).width * .86, 400.0);

    return Drawer(
      width: width,
      backgroundColor: AppColors.coal,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: .2))),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Container(height: 1, color: AppColors.line),
              Expanded(child: _messages(me)),
              _composer(me, muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SOHBET', style: AppTheme.label(color: AppColors.gold)),
                const SizedBox(height: 3),
                Text(
                  widget.group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.serif(size: 20, weight: FontWeight.w400),
                ),
              ],
            ),
          ),
          CircleIconButton(
            icon: Icons.close_rounded,
            size: 40,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _messages(AppUser me) {
    return StreamBuilder<List<ChatMessage>>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 1.6));
        }
        final list = snap.data ?? const <ChatMessage>[];
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'Henüz mesaj yok.\nİlk selamı sen ver.',
                textAlign: TextAlign.center,
                style: AppTheme.serif(size: 17, color: AppColors.textDim, style: FontStyle.italic, height: 1.5),
              ),
            ),
          );
        }
        return ListView.separated(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _Bubble(msg: list[i], isMe: list[i].senderId == me.uid),
        );
      },
    );
  }

  Widget _composer(AppUser me, bool muted) {
    if (muted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_off_rounded, size: 18, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Bu loncada susturuldun, şu an mesaj gönderemezsin.',
                style: AppTheme.sans(size: 13, color: AppColors.textDim),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: AppColors.coal,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(me),
              decoration: InputDecoration(
                hintText: 'Mesaj yaz...',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.gold.withValues(alpha: .7)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleIconButton(
            icon: Icons.arrow_upward_rounded,
            filled: true,
            size: 46,
            onTap: () => _send(me),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _Bubble({required this.msg, required this.isMe});

  @override
  Widget build(BuildContext context) {
    if (msg.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Text(
          msg.text,
          textAlign: TextAlign.center,
          style: AppTheme.sans(size: 12, color: AppColors.textFaint, style: FontStyle.italic),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 270),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
          decoration: BoxDecoration(
            color: isMe ? AppColors.gold.withValues(alpha: .14) : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 18),
            ),
            border: Border.all(
              color: isMe ? AppColors.gold.withValues(alpha: .35) : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) ...[
                Text(
                  msg.senderName,
                  style: AppTheme.sans(size: 11.5, weight: FontWeight.w700, color: AppColors.gold),
                ),
                const SizedBox(height: 3),
              ],
              Text(msg.text, style: AppTheme.sans(size: 14, height: 1.4)),
              const SizedBox(height: 4),
              Text(
                timeOfDay(msg.createdAt),
                style: AppTheme.sans(size: 10, color: AppColors.textFaint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

