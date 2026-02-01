import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@RoutePage()
class ProfileAppScreen extends StatefulWidget {
  const ProfileAppScreen({super.key});

  @override
  State<ProfileAppScreen> createState() => _ProfileAppScreenState();
}

class _ProfileAppScreenState extends State<ProfileAppScreen> {
  String _appVersion = 'Загрузка...';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = 'Версия: ${info.version}';
    });
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Кэш успешно очищен')));
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Удалить аккаунт?'),
            content: const Text(
              'Вы уверены, что хотите безвозвратно удалить свой аккаунт?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Удалим документ из Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .delete();
        // Удалим аккаунт из Firebase Auth
        await user.delete();

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Аккаунт удалён')));
        // Здесь можно добавить логику, например, редирект на экран логина
      }
    } catch (e) {
      debugPrint('Ошибка при удалении аккаунта: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить аккаунт')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(_appVersion, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
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
                      // TODO: Логика для "Напишите нам"
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
                      // TODO: Логика для "Рейтинг"
                    },
                  ),
                  CustomListTile(
                    title: 'Очистить кэш',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: _clearCache,
                  ),
                  CustomListTile(
                    title: 'Правила сервиса',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // TODO: Логика для "Правила сервиса"
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
                      // TODO: Логика для "Политика конфиденциальности"
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
                    onTap: _deleteAccount,
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
                    leadingAsset: 'assets/images/vk.png',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // TODO: Логика для "ВКонтакте"
                    },
                  ),
                  CustomListTile(
                    title: 'Telegram',
                    leadingAsset: 'assets/images/tg.png',
                    icon: const IconWidget(
                      iconName: 'right',
                      size: 10,
                      color: AppColors.gray,
                    ),
                    onTap: () {
                      // TODO: Логика для "Telegram"
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
