import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        'question': 'Как изменить профиль?',
        'answer':
            'Перейдите в раздел "Личные данные" и нажмите "Редактировать".',
      },
      {
        'question': 'Как восстановить пароль?',
        'answer':
            'На экране входа нажмите "Забыли пароль?" и следуйте инструкциям.',
      },
      {
        'question': 'Как работает подписка?',
        'answer':
            'Подписка предоставляет доступ к дополнительным функциям и контенту.',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Помощь')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return CustomExpansionTile(
                    title: faq['question'] ?? '',
                    content: faq['answer'] ?? '',
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Остались вопросы? Напишите в поддержку',
                    style: TextStyle(fontSize: 14, color: AppColors.gray),
                  ),
                  const Square(),
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Написать',
                      theme: 'light',
                      textColor: AppColors.violet,
                      onPressed:
                          () => AutoRouter.of(
                            context,
                          ).push(ProfileFeedbackRoute()),
                    ),
                  ),
                  const Square(height: 42),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String content;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  _CustomExpansionTileState createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
