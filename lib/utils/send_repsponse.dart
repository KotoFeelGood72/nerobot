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

class _ModalBody extends StatefulWidget {
  const _ModalBody({required this.taskId, required this.controller});

  final String taskId;
  final TextEditingController controller;

  @override
  State<_ModalBody> createState() => _ModalBodyState();
}

class _ModalBodyState extends State<_ModalBody> {
  bool _sending = false;

  /// Принимает текст отклика, обновляет массив responses в документе заказа
  /// и создаёт отдельный документ в коллекции "responses" с полной информацией.
  Future<void> _send() async {
    final String text = widget.controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _sending = true);

    try {
      final String uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Ссылки на коллекцию "orders" и нужный документ заказа:
      final DocumentReference<Map<String, dynamic>> orderRef = FirebaseFirestore
          .instance
          .collection('orders')
          .doc(widget.taskId);

      // Загружаем документ заказа, чтобы взять оттуда creator:
      final DocumentSnapshot<Map<String, dynamic>> orderSnap =
          await orderRef.get();
      if (!orderSnap.exists) {
        throw 'Задание не найдено';
      }

      // Получаем UID создателя заказа
      final String? creatorId = orderSnap.data()!['creator'] as String?;

      // Текущий timestamp в миллисекундах:
      final int nowMs = DateTime.now().millisecondsSinceEpoch;

      // 2. Обновляем поле "responses" в документе заказа (добавляем uid)
      await orderRef.update({
        'responses': FieldValue.arrayUnion([uid]),
      });

      // 3. Создаём новый документ в коллекции "responses"
      // в соответствии со структурой, показанной на скриншоте:
      await FirebaseFirestore.instance.collection('responses').add({
        'order': widget.taskId, // ID заказа
        'order_creator': creatorId ?? '', // UID создателя (клиента)
        'respondent': uid, // UID пользователя, откликающегося
        'cover_letter': text, // Текст отклика
        'respondent_rating': 0, // Начальный рейтинг откликнувшегося
        'created_time': nowMs, // Временная метка (ms)
        'created_date': nowMs, // Если нужно хранить дату отдельно
        'active': true, // По умолчанию true (или ваше значение)
        'hidden': false, // По умолчанию false (или ваше значение)
      });

      if (!mounted) return;

      // Закрываем модалку и показываем SnackBar
      AutoRouter.of(context).replace(TaskRoute());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Отклик отправлен')));

      // 4. Очищаем форму (необязательно, ведь мы закрыли модалку)
      widget.controller.clear();

      // 5. Переходим сразу в чат — проверяем, есть ли чат для этого заказа + participants
      final CollectionReference<Map<String, dynamic>> chatsRef =
          FirebaseFirestore.instance.collection('chats');

      // Сначала пробуем найти уже существующий чат по условию:
      // order_id == taskId  AND  participants arrayContains uid
      final QuerySnapshot<Map<String, dynamic>> prevChats =
          await chatsRef
              .where('order_id', isEqualTo: widget.taskId)
              .where('participants', arrayContains: uid)
              .limit(1)
              .get();

      String chatId;
      if (prevChats.docs.isNotEmpty) {
        // Чат уже есть, просто добавляем сообщение туда
        final DocumentSnapshot<Map<String, dynamic>> chatDoc =
            prevChats.docs.first;
        chatId = chatDoc.id;
        await chatsRef.doc(chatId).update({
          'messages': FieldValue.arrayUnion([
            {'sender': uid, 'text': text, 'date_time': nowMs},
          ]),
        });
      } else {
        // Чата ещё не было — создаём новый
        final DocumentReference<Map<String, dynamic>> newChatDoc =
            await chatsRef.add({
              'order_id': widget.taskId,
              'created_date': nowMs,
              'messages': [
                {'sender': uid, 'text': text, 'date_time': nowMs},
              ],
              'participants': [if (creatorId != null) creatorId, uid],
            });
        chatId = newChatDoc.id;
      }

      // 6. Переходим на экран чата
      AutoRouter.of(
        context,
      ).push(ChatsRoute(chatsId: chatId, taskId: widget.taskId));
    } catch (e) {
      // Показ ошибки, если что-то пошло не так
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
