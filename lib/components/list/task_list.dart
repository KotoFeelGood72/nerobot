import 'package:flutter/material.dart';
import 'package:nerobot/components/card/card_task.dart';
import 'package:nerobot/components/placeholder/customers_none_tasks.dart';

class TaskList extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;
  final bool isLoading;
  final Object? error;
  final Function(Map<String, dynamic>)? onTaskTap;

  /// Если true — возвращает sliver для общего скролла со страницей.
  final bool asSliver;

  const TaskList({
    super.key,
    required this.tasks,
    this.isLoading = false,
    this.error,
    this.onTaskTap,
    this.asSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    if (asSliver) return _buildSliver();

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: _errorText());
    }

    if (tasks.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 250,
          child: const CustomersNoneTasks(),
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => _taskItem(tasks[index]),
    );
  }

  Widget _buildSliver() {
    if (isLoading) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: _errorText()),
      );
    }

    if (tasks.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: CustomersNoneTasks(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _taskItem(tasks[index]),
          childCount: tasks.length,
        ),
      ),
    );
  }

  Widget _errorText() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Не удалось загрузить задания.\nPull to refresh и проверьте интернет.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey[700]),
      ),
    );
  }

  Widget _taskItem(Map<String, dynamic> task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CardTask(task: task, onTap: () => onTaskTap?.call(task)),
    );
  }
}
