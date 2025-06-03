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

  // ───────────────── helpers ─────────────────
  Stream<DocumentSnapshot<Map<String, dynamic>>> get _chatStream =>
      FirebaseFirestore.instance.collection('chats').doc(chatsId).snapshots();

  Future<String> _chatTitle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final snap =
        await FirebaseFirestore.instance.collection('chats').doc(chatsId).get();
    final List parts = snap.data()?['participants'] ?? [];
    return parts.firstWhere((p) => p != uid, orElse: () => 'Чат');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _chatTitle(),
          builder:
              (_, s) => Text(
                s.data ??
                    (s.connectionState == ConnectionState.waiting
                        ? 'Загрузка…'
                        : 'Чат'),
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed:
                () => AutoRouter.of(
                  context,
                ).push(TaskDetailCustomerRoute(taskId: taskId)),
          ),
        ],
      ),

      body: Column(
        children: [
          // ---------- сообщения ----------
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _chatStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data?.data();
                final List msgs =
                    (data?['messages'] ?? [])..sort(
                      // newest first
                      (a, b) =>
                          (b['date_time'] as num).compareTo(a['date_time']),
                    );

                if (msgs.isEmpty) {
                  return const Center(child: Text('Нет сообщений'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i] as Map<String, dynamic>;
                    return MessageBubble(
                      message: m,
                      isMine: m['sender'] == uid,
                    );
                  },
                );
              },
            ),
          ),

          // ---------- ввод ----------
          MessageInput(chatId: chatsId, orderId: taskId),
        ],
      ),
    );
  }
}
