import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class NewDescScreen extends StatefulWidget {
  const NewDescScreen({super.key});

  @override
  State<NewDescScreen> createState() => _NewDescScreenState();
}

class _NewDescScreenState extends State<NewDescScreen> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _continue() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Описание не может быть пустым")),
      );
      return;
    }

    // Передаём описание в следующий экран через аргументы, если нужно
    AutoRouter.of(context).push(NewConfirmTaskRoute());
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
            Btn(text: "Продолжить", onPressed: _continue, theme: 'violet'),
            const Square(),
          ],
        ),
      ),
    );
  }
}
