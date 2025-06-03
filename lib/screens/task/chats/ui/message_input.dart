import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';

class MessageInput extends StatefulWidget {
  final String chatId; // ID документа из коллекции `chats`
  final String orderId; // нужен, чтобы сохранять в сообщение order_id

  const MessageInput({super.key, required this.chatId, required this.orderId});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

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
      'text': text, // 👈 теперь поле называется exactly `text`
      'sender': user.uid,
      'date_time': ts,
    };

    try {
      // 1. отдельная коллекция `messages`
      await FirebaseFirestore.instance.collection('messages').add(msg);

      // 2. дублируем в документ чата, чтобы хранить историю внутри `chats`
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
            'messages': FieldValue.arrayUnion([msg]),
          });

      _controller.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка отправки: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      height: 80,
      child: Row(
        children: [
          Expanded(
            child: Inputs(
              controller: _controller,
              backgroundColor: AppColors.bg,
              textColor: Colors.black,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.violet),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
