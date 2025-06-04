// new_desc_screen.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/models/task_draft.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage() // просто помечаем, что этот экран – маршрут
class NewDescScreen extends StatefulWidget {
  final TaskDraft draft;

  // Убираем @PathParam, оставляем просто required this.draft
  const NewDescScreen({Key? key, required this.draft}) : super(key: key);

  @override
  State<NewDescScreen> createState() => _NewDescScreenState();
}

class _NewDescScreenState extends State<NewDescScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Если в задании уже могло быть описание (например, при возврате назад),
    // подгружаем его в контроллер:
    _descriptionController.text = widget.draft.description ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Описание не может быть пустым")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Обновляем поле description в черновике
    widget.draft.description = description;

    // Переходим на экран подтверждения, передавая draft
    await AutoRouter.of(context).push(NewConfirmTaskRoute(draft: widget.draft));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Описание задания",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                maxLength: 300,
                decoration: const InputDecoration(
                  hintText:
                      "Опишите ваше задание максимально подробно и понятно...",
                  hintStyle: TextStyle(color: AppColors.light),
                  border: InputBorder.none,
                  counterText: '',
                ),
              ),
            ),
            const Square(),
            Container(
              width: double.infinity,
              child: Btn(
                text: _isLoading ? "Загрузка..." : "Продолжить",
                onPressed: _isLoading ? null : _continue,
                theme: 'violet',
              ),
            ),
            const Square(),
          ],
        ),
      ),
    );
  }
}
