import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _setRoleAndNavigate(BuildContext context, String role) async {
    AutoRouter.of(context).push(AuthRoute(role: role));
  }

  Future<void> _showLoginRolePicker(BuildContext context) async {
    final role = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Войти как',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Btn(
              text: 'Заказчик',
              theme: 'primary',
              onPressed: () => Navigator.pop(ctx, 'customer'),
            ),
            const SizedBox(height: 8),
            Btn(
              text: 'Исполнитель',
              theme: 'secondary',
              onPressed: () => Navigator.pop(ctx, 'worker'),
            ),
          ],
        ),
      ),
    );

    if (role != null && context.mounted) {
      await _setRoleAndNavigate(context, role);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 70),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 72,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/splash.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Разнорабочий.ру',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Найти исполнителя',
                      theme: 'primary',
                      onPressed: () => _setRoleAndNavigate(context, 'customer'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Стать исполнителем',
                      theme: 'secondary',
                      onPressed: () => _setRoleAndNavigate(context, 'worker'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Btn(
                text: 'Войти в аккаунт',
                theme: 'secondary',
                onPressed: () => _showLoginRolePicker(context),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
