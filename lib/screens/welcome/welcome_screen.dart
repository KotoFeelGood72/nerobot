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
                      theme: 'violet',
                      onPressed: () => _setRoleAndNavigate(context, 'customer'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Стать исполнителем',
                      theme: 'light',
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
                theme: 'white',
                onPressed:
                    () =>
                        AutoRouter.of(context).push(AuthRoute(role: 'worker')),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
