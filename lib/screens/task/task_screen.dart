import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/bar/bottom_nav_bar.dart';
import 'package:nerobot/components/list/task_list.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  // ---------------- state ----------------
  String? role; // worker | customer
  int tabIndex = 0; // активная вкладка
  bool isLoading = true;
  Object? error;
  List<Map<String, dynamic>> tasks = [];
  final Map<String, String> _orderChats = {}; // order_id -> chat_id
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roleSub;

  // ---------- utils ----------
  List<String> get _filters =>
      role == 'worker' ? ['tasks', 'open', 'history'] : ['tasks', 'history'];

  String get _currentFilter => _filters[tabIndex];
  // ---------------------------

  @override
  void initState() {
    super.initState();
    _listenRole(); // ← сразу ставим слушателя
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    super.dispose();
  }

  Future<String> _getOrCreateChat(String orderId) async {
    // 1. кеш
    if (_orderChats.containsKey(orderId)) return _orderChats[orderId]!;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final chatsColl = FirebaseFirestore.instance.collection('chats');

    // 2. ищем готовый чат
    final qSnap =
        await chatsColl
            .where('order_id', isEqualTo: orderId)
            .where('participants', arrayContains: uid)
            .limit(1)
            .get();

    if (qSnap.docs.isNotEmpty) {
      final chatId = qSnap.docs.first.id;
      _orderChats[orderId] = chatId;
      return chatId;
    }

    // 3. чата нет → создаём
    final now = DateTime.now().millisecondsSinceEpoch;
    final newDoc = await chatsColl.add({
      'order_id': orderId,
      'created_date': now,
      'participants': [uid], // автор отклика; второй участник добавится позже
      'messages': [],
    });

    _orderChats[orderId] = newDoc.id;
    return newDoc.id;
  }

  // ================= ROLE LISTENER =================
  void _listenRole() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _roleSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) async {
          final newRole = snap.data()?['type'] ?? 'customer';
          if (newRole != role) {
            // роль поменялась → обновляем стейт и заново грузим список
            setState(() {
              role = newRole;
              tabIndex = 0; // всегда начинаем с первой вкладки
              isLoading = true;
            });
            await _loadTasks(); // подтягиваем задачи под новую роль
          }
        });
  }
  // =================================================

  // ================= LOAD TASKS ====================
  Future<void> _loadTasks() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final uid = FirebaseAuth.instance.currentUser!.uid;
      late Query<Map<String, dynamic>> q;

      // --------------- WORKER ----------------
      if (role == 'worker') {
        switch (_currentFilter) {
          case 'open': // мои отклики
            q = FirebaseFirestore.instance
                .collection('orders')
                .where('active', isEqualTo: true)
                .where('responses', arrayContains: uid);
            break;

          case 'history': // я был исполнителем
            q = FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'completed')
                .where('workers', arrayContains: uid);
            break;

          default: // tasks (новые) — всё активное, *без* моего отклика
            q = FirebaseFirestore.instance
                .collection('orders')
                .where('active', isEqualTo: true);
        }
      }
      // --------------- CUSTOMER ---------------
      else {
        if (_currentFilter == 'history') {
          q = FirebaseFirestore.instance
              .collection('orders')
              .where('creator', isEqualTo: uid)
              .where('status', isEqualTo: 'completed');
        } else {
          q = FirebaseFirestore.instance
              .collection('orders')
              .where('creator', isEqualTo: uid);
        }
      }

      final snap = await q.get();
      var data = snap.docs.map((d) => {...d.data(), 'id': d.id}).toList();

      // фильтр «tasks» для worker: убираем, если уже откликнулся
      if (role == 'worker' && _currentFilter == 'tasks') {
        data =
            data.where((t) {
              final List resps = (t['responses'] ?? []) as List;
              return !resps.contains(uid);
            }).toList();
      }

      setState(() => tasks = data);
    } catch (e) {
      setState(() => error = e);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  // =================================================

  // =================== UI ==========================
  @override
  Widget build(BuildContext context) {
    if (role == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final titles =
        role == 'worker'
            ? ['Новые', 'Открытые', 'История']
            : ['Открытые', 'История'];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Задания $role',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (role != 'worker')
            IconButton(
              icon: const Icon(Icons.add, color: Colors.black),
              onPressed:
                  () => AutoRouter.of(context).push(NewTaskCreateRoute()),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _buildTabs(titles),
        ),
      ),

      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TaskList(
            tasks: tasks,
            isLoading: isLoading,
            error: error,
            onTaskTap: _onTaskTap,
          ),
        ),
      ),

      bottomNavigationBar: const BottomNavBar(),
    );
  }

  Widget _buildTabs(List<String> titles) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.ulight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: List.generate(titles.length, (i) {
          final active = tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => tabIndex = i);
                _loadTasks();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    titles[i],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.violet : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );

  void _onTaskTap(Map<String, dynamic> task) async {
    final orderId = task['id'].toString();

    if (role == 'worker' && _currentFilter == 'open') {
      // гарантируем, что есть chatId
      final chatId = await _getOrCreateChat(orderId);

      if (!mounted) return;
      AutoRouter.of(context).push(ChatsRoute(chatsId: chatId, taskId: orderId));
      return;
    }

    /* остальные ветки не трогали */
    if (role == 'worker') {
      AutoRouter.of(context).push(TaskDetailRoute(taskId: orderId));
    } else {
      AutoRouter.of(context).push(TaskResponseRoute(taskId: orderId));
    }
  }
}
