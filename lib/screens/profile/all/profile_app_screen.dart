import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileAppScreen extends StatelessWidget {
  const ProfileAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Text('Версия: 0.00.0', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              child: Column(
                children: [
                  CustomListTile(
                    title: 'Напишите нам',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                  CustomListTile(
                    title: 'Рейтинг',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                  CustomListTile(
                    title: 'Очистить кэш ',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                  CustomListTile(
                    title: 'Правила сервиса',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                  CustomListTile(
                    title: 'Политика конфиденциальности',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                  CustomListTile(
                    txtColor: AppColors.red,
                    title: 'Удалить аккаунт',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.red,
                    ),
                    onTap: () {
                      // Логика для "Напишите нам"
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              child: Column(
                children: [
                  CustomListTile(
                    title: 'ВКонтакте',
                    leadingAsset:
                        'assets/images/vk.png', // Укажите путь к изображению
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для второго пункта
                    },
                  ),
                  CustomListTile(
                    title: 'Telegram',
                    leadingAsset:
                        'assets/images/tg.png', // Укажите путь к изображению
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // Логика для второго пункта
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomListTile extends StatelessWidget {
  final String title;
  final String? leadingAsset;
  final Widget icon;
  final VoidCallback onTap;
  final Color? txtColor;

  const CustomListTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.txtColor,
    this.leadingAsset,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(width: .5, color: AppColors.border),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (leadingAsset != null) ...[
              Image.asset(leadingAsset!, width: 24, height: 24),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: txtColor ?? AppColors.black,
                ),
              ),
            ),
            icon,
          ],
        ),
      ),
    );
  }
}
