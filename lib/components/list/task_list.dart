import 'package:flutter/material.dart';
import 'package:nerobot/components/card/card_task.dart';
import 'package:nerobot/components/placeholder/customers_none_tasks.dart';

class TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final bool isLoading;
  final Object? error;
  final Function(Map<String, dynamic>)? onTaskTap;

  const TaskList({
    super.key,
    required this.tasks,
    this.isLoading = false,
    this.error,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: CustomersNoneTasks());
    }

    if (tasks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: CustomersNoneTasks(),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: CardTask(task: task, onTap: () => onTaskTap?.call(task)),
        );
      },
    );
  }
}
