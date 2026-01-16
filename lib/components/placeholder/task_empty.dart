import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/router/app_router.gr.dart';

class TaskEmpty extends StatelessWidget {
  const TaskEmpty({super.key});

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
          const Text(
            'Для откликов необходима подписка',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const Square(),
          const Text(
            'Оформите подписку, чтобы видеть доступные задания и оставлять отклики',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Btn(
            text: 'Оформить подписку',
            theme: 'violet',
            onPressed: () {
              AutoRouter.of(context).push(const ProfileSubscriptionRoute());
            },
          ),
        ],
      ),
    );
  }
}








