import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/constants/app_colors.dart';

class MessageInput extends StatefulWidget {
  final String chatId;
  final String orderId;

  const MessageInput({super.key, required this.chatId, required this.orderId});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.chatId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Чат ещё не создан')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пользователь не авторизован')),
      );
      return;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final msg = <String, dynamic>{
      'chat': widget.chatId,
      'order_id': widget.orderId,
      'text': text,
      'sender': user.uid,
      'date_time': ts,
    };

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'messages': FieldValue.arrayUnion([msg]),
          });

      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: AppFormMetrics.controlHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.bg,
                  borderRadius: BorderRadius.circular(AppFormMetrics.radius),
                  border: Border.all(color: AppColors.border),
                ),
                padding: AppFormMetrics.controlPadding,
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Введите текст',
                    hintStyle: TextStyle(
                      color: Colors.black.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              height: AppFormMetrics.controlHeight,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: AppFormMetrics.controlHeight,
                ),
                icon: const Icon(Icons.send, color: AppColors.violet),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
