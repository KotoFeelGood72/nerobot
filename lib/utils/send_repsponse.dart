import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/modal_utils.dart';

Future<void> openResponseModal(BuildContext context, String taskId) {
  final TextEditingController responseController = TextEditingController();

  return showCustomModalBottomSheet(
    context: context,
    scroll: true,
    builder:
        (context) => _ModalBody(taskId: taskId, controller: responseController),
  );
}

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
    final String text = widget.controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      final orderRef =
          FirebaseFirestore.instance.collection('orders').doc(widget.taskId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) {
        throw 'Задание не найдено';
      }

      final creatorId = orderSnap.data()?['creator'] as String?;
      if (creatorId == uid) {
        throw 'Нельзя откликнуться на своё задание';
      }

      final responses = orderSnap.data()?['responses'];
      if (responses is List && responses.contains(uid)) {
        throw 'Вы уже откликнулись на это задание';
      }

      final nowMs = DateTime.now().millisecondsSinceEpoch;

      await orderRef.update({
        'responses': FieldValue.arrayUnion([uid]),
      });

      await FirebaseFirestore.instance.collection('responses').add({
        'order': widget.taskId,
        'order_creator': creatorId ?? '',
        'respondent': uid,
        'cover_letter': text,
        'respondent_rating': 0,
        'created_time': nowMs,
        'created_date': nowMs,
        'active': true,
        'hidden': false,
      });

      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final prevChats = await chatsRef
          .where('order_id', isEqualTo: widget.taskId)
          .where('participants', arrayContains: uid)
          .limit(1)
          .get();

      final message = {'sender': uid, 'text': text, 'date_time': nowMs};
      late String chatId;

      if (prevChats.docs.isNotEmpty) {
        chatId = prevChats.docs.first.id;
        await chatsRef.doc(chatId).update({
          'messages': FieldValue.arrayUnion([message]),
        });
      } else {
        final newChatDoc = await chatsRef.add({
          'order_id': widget.taskId,
          'created_date': nowMs,
          'messages': [message],
          'participants': [if (creatorId != null) creatorId, uid],
        });
        chatId = newChatDoc.id;
      }

      if (!mounted) return;

      // Закрываем модалку и открываем чат поверх экрана заданий
      Navigator.of(context).pop();
      AutoRouter.of(context).replaceAll([
        const TaskRoute(),
        ChatsRoute(chatsId: chatId, taskId: widget.taskId),
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Отклик отправлен')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
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
                  theme: 'secondary',
                  textColor: AppColors.red,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Btn(
                  text: _sending ? 'Отправка…' : 'Отправить',
                  theme: 'primary',
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
