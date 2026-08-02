import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/email_auth_helper.dart';
import 'package:nerobot/utils/push_token_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ProfileAppScreen extends StatefulWidget {
  const ProfileAppScreen({super.key});

  @override
  State<ProfileAppScreen> createState() => _ProfileAppScreenState();
}

class _ProfileAppScreenState extends State<ProfileAppScreen> {
  String _appVersion = 'Загрузка...';
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'Версия: ${info.version}';
    });
  }

  Future<void> _clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    await prefs.clear();
    if (role != null) {
      await prefs.setString('user_role', role);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Кэш успешно очищен')));
  }

  Future<String?> _resolveEmail(User user) async {
    final fromAuth = user.email?.trim();
    if (fromAuth != null && fromAuth.isNotEmpty) return fromAuth;

    final snap =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final fromDoc = (snap.data()?['email'] as String?)?.trim();
    if (fromDoc != null && fromDoc.isNotEmpty) return fromDoc;
    return null;
  }

  Future<String?> _askOtpCode({
    required String email,
    String? debugCode,
  }) async {
    final controller = TextEditingController(
      text: debugCode?.isNotEmpty == true ? debugCode : '',
    );
    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Подтвердите удаление'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Мы отправили код на $email.\nВведите его, чтобы безвозвратно удалить аккаунт.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Код из письма',
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length != 6) return;
                Navigator.pop(ctx, value);
              },
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return code;
  }

  Future<void> _deleteAccount() async {
    if (_isDeleting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Удалить аккаунт?'),
            content: const Text(
              'Будут удалены профиль, задания, отклики, чаты и фото. '
              'Это действие нельзя отменить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Продолжить'),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isDeleting = true);

    try {
      final email = await _resolveEmail(user);
      if (email == null || !EmailAuthHelper.isValidEmail(email)) {
        throw Exception('Не найден email аккаунта для подтверждения');
      }

      final debugCode = await EmailAuthHelper.sendOtp(email);
      if (!mounted) return;

      final code = await _askOtpCode(email: email, debugCode: debugCode);
      if (code == null || code.isEmpty) return;

      await EmailAuthHelper.verifyOtp(email: email, code: code);

      final freshUser = FirebaseAuth.instance.currentUser;
      if (freshUser == null) {
        throw Exception('Сессия не обновлена');
      }

      final userSnap =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(freshUser.uid)
              .get();
      final cityTopic =
          (userSnap.data()?['subscribed_city_topic'] as String?)?.trim();

      await EmailAuthHelper.deleteAccount(email: email);
      await PushTokenManager.clearLocalPushState(cityTopic: cityTopic);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {
        // Auth уже удалён на сервере — это ожидаемо.
      }

      if (!mounted) return;
      AutoRouter.of(context).replaceAll([const WelcomeRoute()]);
    } catch (e) {
      debugPrint('Ошибка при удалении аккаунта: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(EmailAuthHelper.mapError(e))),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openTelegram() async {
    final tgUrl = Uri.parse('tg://resolve?domain=nickelodium');
    final webUrl = Uri.parse('https://t.me/nickelodium');

    try {
      if (await canLaunchUrl(tgUrl)) {
        await launchUrl(tgUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось открыть Telegram. Установите Telegram или откройте https://t.me/nickelodium в браузере',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('О приложении')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        _appVersion,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Column(
                  children: [
                    CustomListTile(
                      title: 'Напишите нам',
                      icon: const IconWidget(
                        iconName: 'right',
                        size: 10,
                        color: AppColors.gray,
                      ),
                      onTap: _isDeleting ? () {} : _openTelegram,
                    ),
                    CustomListTile(
                      title: 'Очистить кэш',
                      icon: const IconWidget(
                        iconName: 'right',
                        size: 10,
                        color: AppColors.gray,
                      ),
                      onTap: _isDeleting ? () {} : _clearCache,
                    ),
                    CustomListTile(
                      title: 'Правила сервиса',
                      icon: const IconWidget(
                        iconName: 'right',
                        size: 10,
                        color: AppColors.gray,
                      ),
                      onTap: _isDeleting
                          ? () {}
                          : () {
                              AutoRouter.of(context)
                                  .push(const ProfileTermsRoute());
                            },
                    ),
                    CustomListTile(
                      title: 'Политика конфиденциальности',
                      icon: const IconWidget(
                        iconName: 'right',
                        size: 10,
                        color: AppColors.gray,
                      ),
                      onTap: _isDeleting
                          ? () {}
                          : () {
                              AutoRouter.of(context)
                                  .push(const ProfilePrivacyRoute());
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
                      onTap: _isDeleting ? () {} : _deleteAccount,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    CustomListTile(
                      title: 'Telegram',
                      leadingAsset: 'assets/images/tg.png',
                      icon: const IconWidget(
                        iconName: 'right',
                        size: 10,
                        color: AppColors.gray,
                      ),
                      onTap: _isDeleting ? () {} : _openTelegram,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isDeleting)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
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
