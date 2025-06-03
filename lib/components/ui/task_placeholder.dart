import 'package:flutter/material.dart';

class TaskPlaceholder extends StatelessWidget {
  final String? errorMessage;
  final bool isErrorShown;
  final VoidCallback? onDismissError;

  const TaskPlaceholder({
    super.key,
    this.errorMessage,
    this.isErrorShown = false,
    this.onDismissError,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (errorMessage != null && !isErrorShown)
            Container(
              margin: const EdgeInsets.only(bottom: 16.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: onDismissError,
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              children: [Text('Список задач будет отображаться здесь.')],
            ),
          ),
        ],
      ),
    );
  }
}
