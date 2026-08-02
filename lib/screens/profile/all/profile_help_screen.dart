import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

@RoutePage()
class ProfileHelpScreen extends StatelessWidget {
  const ProfileHelpScreen({super.key});

  static const _faqs = <Map<String, String>>[
    {
      'question': 'Как войти в приложение?',
      'answer':
          'Укажите email на экране входа — мы пришлём одноразовый код. '
          'Введите код на следующем экране. Пароль не нужен.',
    },
    {
      'question': 'Чем отличаются роли заказчика и исполнителя?',
      'answer':
          'Заказчик публикует задания и выбирает исполнителя. '
          'Исполнитель смотрит новые задания рядом, откликается и выполняет работу. '
          'Роль можно переключить в профиле.',
    },
    {
      'question': 'Как создать задание?',
      'answer':
          'Войдите как заказчик → вкладка «Задания» → создайте новое задание: '
          'название, описание, цена, срок, адрес (на карте или вручную) и тип оплаты. '
          'Перед публикацией укажите город в профиле.',
    },
    {
      'question': 'Почему я не вижу задания рядом?',
      'answer':
          'Укажите город в «Личные данные». Во вкладке «Новые» показываются '
          'открытые задания в радиусе поиска (по умолчанию 50 км, максимум 200 км). '
          'Радиус можно изменить в фильтрах.',
    },
    {
      'question': 'Как откликнуться на задание?',
      'answer':
          'Откройте карточку задания → «Согласиться» → напишите короткое сообщение. '
          'После отклика откроется чат с заказчиком, а задание появится во вкладке «Открытые».',
    },
    {
      'question': 'Где переписка по заданию?',
      'answer':
          'Чат создаётся при первом отклике. Заголовок чата — название задания. '
          'Кнопка «i» открывает детали заказа.',
    },
    {
      'question': 'Как выбрать исполнителя?',
      'answer':
          'Заказчик открывает задание → список откликов → утверждает исполнителя. '
          'После этого статус заказа меняется на «В работе».',
    },
    {
      'question': 'Как изменить профиль и фото?',
      'answer':
          'Аккаунт → «Личные данные» → «Редактировать». '
          'Там можно изменить имя, телефон, город, «О себе» и фото.',
    },
    {
      'question': 'Как настроить уведомления?',
      'answer':
          'Аккаунт → «Уведомления». Можно включить: задания в городе, новые задания, '
          'сообщения в чате, отклики на ваше задание и напоминание, если вы давно не заходили. '
          'Разрешите push в настройках телефона, если система их блокирует.',
    },
    {
      'question': 'Как выйти из аккаунта?',
      'answer':
          'Откройте «Аккаунт» и нажмите «Выйти» внизу экрана.',
    },
  ];

  Future<void> _openSupport(BuildContext context) async {
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
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось открыть Telegram. Установите приложение '
            'или откройте https://t.me/nickelodium',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Помощь')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _faqs.length,
                  itemBuilder: (context, index) {
                    final faq = _faqs[index];
                    return CustomExpansionTile(
                      title: faq['question'] ?? '',
                      content: faq['answer'] ?? '',
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Остались вопросы? Напишите в поддержку',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.gray),
              ),
              const Square(),
              SizedBox(
                width: double.infinity,
                child: Btn(
                  text: 'Написать',
                  theme: 'primary',
                  onPressed: () => _openSupport(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final String title;
  final String content;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.content,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
