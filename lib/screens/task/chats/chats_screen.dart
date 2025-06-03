// chats_screen.dart
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/screens/task/chats/ui/message_bubble.dart';
import 'package:nerobot/screens/task/chats/ui/message_input.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.chatsId, required this.taskId});

  final String chatsId;
  final String taskId;

  /// Поток для чтения документа чата
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _chatStream =>
      FirebaseFirestore.instance.collection('chats').doc(chatsId).snapshots();

  /// Получаем UID текущего пользователя
  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _navigateToTaskDetail(BuildContext context) async {
    final myUid = _myUid;

    if (myUid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final role = userDoc.data()?['type'] as String? ?? '';

    if (role == 'customer') {
      final chatSnap =
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatsId)
              .get();

      final List participants = chatSnap.data()?['participants'] ?? [];
      final respondentUid = participants.firstWhere(
        (uid) => uid != myUid,
        orElse: () => myUid,
      );

      print('respondentUid $respondentUid');

      if (respondentUid != null) {
        AutoRouter.of(context).push(
          TaskDetailCustomerRoute(taskId: taskId, respondent: respondentUid),
        );
      }
    } else {
      AutoRouter.of(context).push(TaskDetailRoute(taskId: taskId));
    }
  }

  /// Функция, которая возвращает имя «другого» участника чата (то есть того, чей UID
  /// не совпадает с _myUid). Если такого нет, возвращаем просто «Чат».
  Future<String> _chatTitle() async {
    if (_myUid == null) return 'Чат';

    // Сначала достаём документ чата (чтобы узнать, кто там участвует)
    final chatSnap =
        await FirebaseFirestore.instance.collection('chats').doc(chatsId).get();

    if (!chatSnap.exists) {
      return 'Чат';
    }

    final data = chatSnap.data();
    final List participants = data?['participants'] ?? [];

    // Ищем первого участника, чей UID != _myUid
    final otherUid = participants.firstWhere(
      (p) => p != _myUid,
      orElse: () => null,
    );

    if (otherUid == null) {
      return 'Чат';
    }

    // Теперь по UID другого участника читаем его данные из коллекции 'users'
    final userSnap =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUid)
            .get();

    if (!userSnap.exists) {
      return 'Чат';
    }

    final userData = userSnap.data();
    final String firstName = userData?['firstName'] ?? '';
    final String lastName = userData?['lastName'] ?? '';

    // Если вдруг имя или фамилия пусты, просто вернём «Чат»
    if (firstName.isEmpty && lastName.isEmpty) {
      return 'Чат';
    }

    return '$firstName $lastName';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Заголовок через FutureBuilder: пока ждём имени – показываем «Загрузка…»
        title: FutureBuilder<String>(
          future: _chatTitle(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Загрузка…');
            }
            if (snapshot.hasError) {
              return const Text('Чат');
            }
            // snapshot.data может быть null (если, например, участник не найден)
            final titleText = snapshot.data ?? 'Чат';
            return Text(titleText);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _navigateToTaskDetail(context),
          ),
        ],
      ),

      body: Column(
        children: [
          // ---------- Сообщения ----------
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _chatStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: Text('Чат не найден'));
                }

                final data = snap.data!.data();
                final List msgs =
                    (data?['messages'] ?? [])..sort(
                      (a, b) => (b['date_time'] as num).compareTo(
                        a['date_time'] as num,
                      ),
                    ); // новейшие сверху

                if (msgs.isEmpty) {
                  return const Center(child: Text('Нет сообщений'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final m = msgs[index] as Map<String, dynamic>;
                    final isMine = m['sender'] == _myUid;
                    return MessageBubble(message: m, isMine: isMine);
                  },
                );
              },
            ),
          ),

          // ---------- Поле ввода нового сообщения ----------
          MessageInput(chatId: chatsId, orderId: taskId),
        ],
      ),
    );
  }
}
