import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileTermsScreen extends StatelessWidget {
  const ProfileTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Правила сервиса',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1. Общие положения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1.1. Настоящие Правила сервиса (далее — «Правила») определяют порядок использования сервиса Nerobot (далее — «Сервис»).\n\n'
              '1.2. Используя Сервис, вы соглашаетесь с данными Правилами.\n\n'
              '1.3. Администрация Сервиса оставляет за собой право изменять Правила в любое время без предварительного уведомления.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Регистрация и использование',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '2.1. Для использования Сервиса необходимо пройти регистрацию.\n\n'
              '2.2. Пользователь обязуется предоставлять достоверную информацию при регистрации.\n\n'
              '2.3. Пользователь несет ответственность за сохранность своих учетных данных.\n\n'
              '2.4. Запрещается передавать свои учетные данные третьим лицам.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '3. Создание и выполнение заданий',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '3.1. Заказчик имеет право создавать задания с четким описанием требований.\n\n'
              '3.2. Исполнитель обязуется выполнять задания в соответствии с требованиями заказчика.\n\n'
              '3.3. Запрещается создавать задания, нарушающие законодательство или права третьих лиц.\n\n'
              '3.4. Оплата производится после успешного выполнения задания.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '4. Ответственность',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '4.1. Сервис предоставляется «как есть» без гарантий.\n\n'
              '4.2. Администрация не несет ответственности за действия пользователей.\n\n'
              '4.3. Пользователи несут полную ответственность за размещаемый контент и выполняемые действия.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '5. Конфиденциальность',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '5.1. Администрация обязуется защищать персональные данные пользователей в соответствии с законодательством.\n\n'
              '5.2. Подробная информация о обработке данных указана в Политике конфиденциальности.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '6. Заключительные положения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '6.1. Администрация оставляет за собой право блокировать аккаунты пользователей, нарушающих Правила.\n\n'
              '6.2. Все споры решаются путем переговоров, а при невозможности — в соответствии с законодательством.\n\n'
              '6.3. По вопросам, не урегулированным настоящими Правилами, применяется действующее законодательство.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
