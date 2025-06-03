import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/modal_utils.dart';

void openResponseModal(BuildContext context, String taskId) {
  final TextEditingController responseController = TextEditingController();

  showCustomModalBottomSheet(
    context: context,
    scroll: true,
    builder:
        (context) => _ModalBody(taskId: taskId, controller: responseController),
  );
}

/* ----------------------------- BODY ------------------------------------ */

class _ModalBody extends StatefulWidget {
  const _ModalBody({required this.taskId, required this.controller});

  final String taskId;
  final TextEditingController controller;

  @override
  State<_ModalBody> createState() => _ModalBodyState();
}

class _ModalBodyState extends State<_ModalBody> {
  bool _sending = false;

  Future<void> _send() async {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.taskId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) throw 'Задание не найдено';

      final creatorId = orderSnap.data()!['creator'] as String?;

      /* ---- 1. Обновляем responses у задачи ---- */
      await orderRef.update({
        'responses': FieldValue.arrayUnion([uid]),
      });

      /* ---- 2. Создаём (или берём существующий) чат ---- */
      final chats = FirebaseFirestore.instance.collection('chats');

      // ищем чат, где эта задача и уже есть текущий пользователь
      final prev =
          await chats
              .where('order_id', isEqualTo: widget.taskId)
              .where('participants', arrayContains: uid)
              .limit(1)
              .get();

      late String chatId;

      if (prev.docs.isNotEmpty) {
        // чат уже был — добавим сообщение
        final doc = prev.docs.first;
        chatId = doc.id;
        await chats.doc(chatId).update({
          'messages': FieldValue.arrayUnion([
            {
              'sender': uid,
              'text': text,
              'date_time': DateTime.now().millisecondsSinceEpoch,
            },
          ]),
        });
      } else {
        // создаём новый чат
        final doc = await chats.add({
          'order_id': widget.taskId,
          'created_date': DateTime.now().millisecondsSinceEpoch,
          'messages': [
            {
              'sender': uid,
              'text': text,
              'date_time': DateTime.now().millisecondsSinceEpoch,
            },
          ],
          'participants': [if (creatorId != null) creatorId, uid],
        });
        chatId = doc.id;
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // закрываем модалку

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Отклик отправлен')));

      // переходим в чат
      AutoRouter.of(
        context,
      ).push(ChatsRoute(chatsId: chatId, taskId: widget.taskId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Написать отклик',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          Inputs(
            controller: widget.controller,
            backgroundColor: Colors.white,
            textColor: Colors.black,
            label: 'Ваш отклик',
            fieldType: 'text',
            isMultiline: true,
            required: true,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Btn(
                  text: 'Отмена',
                  theme: 'white',
                  textColor: AppColors.red,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Btn(
                  text: _sending ? 'Отправка…' : 'Отправить',
                  theme: 'violet',
                  disabled: _sending,
                  onPressed: _sending ? null : _send,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
