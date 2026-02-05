import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Политика конфиденциальности',
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
              '1.1. Настоящая Политика конфиденциальности (далее — «Политика») определяет порядок обработки и защиты персональных данных пользователей сервиса Nerobot (далее — «Сервис»).\n\n'
              '1.2. Используя Сервис, вы даете согласие на обработку ваших персональных данных в соответствии с настоящей Политикой.\n\n'
              '1.3. Администрация Сервиса обязуется соблюдать конфиденциальность персональных данных пользователей.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '2. Собираемые данные',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '2.1. При регистрации и использовании Сервиса мы собираем следующие данные:\n'
              '• Имя и контактная информация (телефон, email)\n'
              '• Данные профиля (фотография, описание)\n'
              '• Геолокационные данные (для определения местоположения заданий)\n'
              '• Данные об использовании Сервиса (история заданий, отзывы, рейтинг)\n'
              '• Технические данные (IP-адрес, тип устройства, версия приложения)\n\n'
              '2.2. Мы не собираем данные, не относящиеся к предоставлению услуг Сервиса.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '3. Цели обработки данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '3.1. Персональные данные обрабатываются в следующих целях:\n'
              '• Предоставление услуг Сервиса\n'
              '• Связь с пользователями по вопросам использования Сервиса\n'
              '• Улучшение качества услуг\n'
              '• Обеспечение безопасности и предотвращение мошенничества\n'
              '• Выполнение обязательств перед пользователями\n\n'
              '3.2. Данные не используются для целей, не указанных в настоящей Политике.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '4. Защита данных',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '4.1. Администрация применяет технические и организационные меры для защиты персональных данных от неправомерного доступа, уничтожения, изменения или распространения.\n\n'
              '4.2. Доступ к персональным данным имеют только уполномоченные сотрудники, которым это необходимо для выполнения служебных обязанностей.\n\n'
              '4.3. Данные хранятся на защищенных серверах с использованием современных технологий шифрования.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '5. Передача данных третьим лицам',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '5.1. Администрация не передает персональные данные третьим лицам, за исключением случаев:\n'
              '• Получения явного согласия пользователя\n'
              '• Требований законодательства\n'
              '• Защиты прав и безопасности пользователей\n\n'
              '5.2. При передаче данных третьим лицам обеспечивается их конфиденциальность и безопасность.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '6. Права пользователей',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '6.1. Пользователь имеет право:\n'
              '• Получать информацию о своих персональных данных\n'
              '• Требовать исправления неточных данных\n'
              '• Требовать удаления персональных данных\n'
              '• Отозвать согласие на обработку данных\n'
              '• Ограничить обработку данных\n\n'
              '6.2. Для реализации своих прав пользователь может обратиться в поддержку Сервиса.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '7. Cookies и аналогичные технологии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '7.1. Сервис может использовать cookies и аналогичные технологии для улучшения работы приложения.\n\n'
              '7.2. Пользователь может настроить браузер для отказа от cookies, однако это может ограничить функциональность Сервиса.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '8. Изменения в Политике',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '8.1. Администрация оставляет за собой право вносить изменения в настоящую Политику.\n\n'
              '8.2. О существенных изменениях пользователи будут уведомлены через приложение или по электронной почте.\n\n'
              '8.3. Продолжение использования Сервиса после внесения изменений означает согласие с новой версией Политики.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '9. Контакты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '9.1. По вопросам, связанным с обработкой персональных данных, вы можете обратиться в поддержку Сервиса через раздел "Помощь" в приложении или написать в Telegram: @nickelodium.',
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
