import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/router/app_router.gr.dart';

class CustomersNoneTasks extends StatelessWidget {
  final String title;
  final String text;
  final bool btn;
  final String? role;

  const CustomersNoneTasks({
    super.key,
    this.title = 'У вас сейчас нет заданий',
    this.text = 'Открытые задания появятся здесь',
    this.btn = true,
    this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(bottom: 16),
            width: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/splash.png', fit: BoxFit.cover),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Square(),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          if (role == 'Customer' && btn)
            Btn(
              text: 'Создать задание',
              theme: 'white',
              onPressed: () {
                AutoRouter.of(context).push(NewTaskCreateRoute());
              },
            ),
        ],
      ),
    );
  }
}
