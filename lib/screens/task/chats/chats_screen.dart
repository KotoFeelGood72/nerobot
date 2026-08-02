import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/screens/task/chats/ui/message_bubble.dart';
import 'package:nerobot/screens/task/chats/ui/message_input.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.chatsId, required this.taskId});

  final String chatsId;
  final String taskId;

  Stream<DocumentSnapshot<Map<String, dynamic>>> get _chatStream =>
      FirebaseFirestore.instance.collection('chats').doc(chatsId).snapshots();

  String? get _myUid => FirebaseAuth.instance.currentUser?.uid;

  void _goToTasks(BuildContext context) {
    AutoRouter.of(context).replaceAll([const TaskRoute()]);
  }

  Future<void> _navigateToTaskDetail(BuildContext context) async {
    final myUid = _myUid;
    if (myUid == null) return;

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final role = userDoc.data()?['type'] as String? ?? '';

    if (!context.mounted) return;

    if (role == 'customer') {
      final chatSnap = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatsId)
          .get();

      final List participants = chatSnap.data()?['participants'] ?? [];
      final respondentUid = participants.firstWhere(
        (uid) => uid != myUid,
        orElse: () => myUid,
      );

      if (!context.mounted) return;
      AutoRouter.of(context).push(
        TaskDetailCustomerRoute(taskId: taskId, respondent: respondentUid),
      );
    } else {
      AutoRouter.of(context).push(TaskDetailRoute(taskId: taskId));
    }
  }

  /// Название задания в шапке чата
  Future<String> _taskTitle() async {
    try {
      final orderSnap = await FirebaseFirestore.instance
          .collection('orders')
          .doc(taskId)
          .get();
      final title = orderSnap.data()?['title']?.toString().trim();
      if (title != null && title.isNotEmpty) return title;
    } catch (_) {}
    return 'Чат задания';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToTasks(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _goToTasks(context),
          ),
          title: FutureBuilder<String>(
            future: _taskTitle(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Text('Загрузка…');
              }
              return Text(
                snapshot.data ?? 'Чат задания',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => _navigateToTaskDetail(context),
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(width: 1, color: AppColors.border)),
          ),
          child: Column(
            children: [
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
                    final List msgs = List.of(data?['messages'] ?? []);
                    msgs.sort((a, b) {
                      final aTime =
                          a is Map ? (a['date_time'] as num?) ?? 0 : 0;
                      final bTime =
                          b is Map ? (b['date_time'] as num?) ?? 0 : 0;
                      return bTime.compareTo(aTime);
                    });

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
              MessageInput(chatId: chatsId, orderId: taskId),
            ],
          ),
        ),
      ),
    );
  }
}
