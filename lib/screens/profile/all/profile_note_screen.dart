import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/utils/notification_constants.dart';
import 'package:nerobot/utils/push_token_manager.dart';

@RoutePage()
class ProfileNoteScreen extends StatefulWidget {
  const ProfileNoteScreen({super.key});

  @override
  State<ProfileNoteScreen> createState() => _ProfileNoteScreenState();
}

class _ProfileNoteScreenState extends State<ProfileNoteScreen> {
  final Map<String, bool> _prefs = Map<String, bool>.from(
    NotificationPrefs.defaults,
  );
  bool _isLoading = true;

  static const _options = <Map<String, String>>[
    {
      'key': NotificationPrefs.cityTask,
      'title': 'Задания в моём городе',
      'subtitle': 'Есть задание в вашем городе',
    },
    {
      'key': NotificationPrefs.newTasks,
      'title': 'Новые задания',
      'subtitle': 'Появились новые заказы для исполнителей',
    },
    {
      'key': NotificationPrefs.messages,
      'title': 'Сообщения в чате',
      'subtitle': 'Вам написали сообщение',
    },
    {
      'key': NotificationPrefs.orderResponse,
      'title': 'Отклики на задание',
      'subtitle': 'На ваше задание откликнулись',
    },
    {
      'key': NotificationPrefs.inactiveReminder,
      'title': 'Напоминание о входе',
      'subtitle': 'Вы давно не заходили в приложение',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await PushTokenManager.registerCurrentDevice();
      final prefs = await PushTokenManager.loadPreferences();
      if (!mounted) return;
      setState(() {
        _prefs
          ..clear()
          ..addAll(prefs);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ProfileNoteScreen load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onToggle(String key, bool value) async {
    setState(() => _prefs[key] = value);
    try {
      await PushTokenManager.updatePreference(key: key, enabled: value);
    } catch (e) {
      debugPrint('Failed to update notification pref: $e');
      if (!mounted) return;
      setState(() => _prefs[key] = !value);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить настройку')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выберите, о чём получать push-уведомления',
                style: TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _options[index];
                    final key = item['key']!;
                    final enabled = _prefs[key] ?? true;
                    return _buildSwitchTile(
                      title: item['title']!,
                      subtitle: item['subtitle']!,
                      value: enabled,
                      onChanged: (value) => _onToggle(key, value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Разрешите уведомления в настройках телефона, если система их блокирует.',
                style: TextStyle(fontSize: 13, color: AppColors.gray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: value ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: AppColors.gray),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
