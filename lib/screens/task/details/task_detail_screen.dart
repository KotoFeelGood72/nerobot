import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/screens/task/customers/task_response_screen.dart';
import 'package:nerobot/screens/task/details/executor/task_detail_executor.dart';

@RoutePage()
class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({
    super.key,
    @PathParam('taskId') required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  String? userRole;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception("Пользователь не авторизован");

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (!doc.exists) throw Exception("Профиль пользователя не найден");

      final type = doc.data()?['type'];
      if (mounted) {
        setState(() {
          userRole = type?.toString().toLowerCase(); // worker / customer
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userRole = null;
          isLoading = false;
        });
      }
      debugPrint('Ошибка при загрузке роли: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    Widget screen;

    if (userRole == 'worker') {
      screen = TaskDetailExecutorScreen(taskId: widget.taskId);
    } else if (userRole == 'customer') {
      screen = TaskResponseScreen(taskId: widget.taskId);
    } else {
      screen = const Center(child: Text('Роль не определена'));
    }

    return Scaffold(appBar: AppBar(title: Text('Детали задачи')), body: screen);
  }
}
