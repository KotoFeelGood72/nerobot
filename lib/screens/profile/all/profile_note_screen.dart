
import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileNoteScreen extends StatefulWidget {
  const ProfileNoteScreen({super.key});

  @override
  _ProfileNoteScreenState createState() => _ProfileNoteScreenState();
}

class _ProfileNoteScreenState extends State<ProfileNoteScreen> {
  bool isCandidateEnabled = true;
  bool isCityTaskEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              title: 'В списке кандидатов',
              value: isCandidateEnabled,
              onChanged: (value) {
                setState(() {
                  isCandidateEnabled = value;
                });
              },
            ),
            _buildSwitchTile(
              title: 'Задание в моём городе',
              value: isCityTaskEnabled,
              onChanged: (value) {
                setState(() {
                  isCityTaskEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Включите push-уведомления, чтобы узнавать о новых событиях',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Btn(
                text: 'Настроить уведомления',
                onPressed: () {
                  // Логика для настройки уведомлений
                },
                theme: 'light',
                textColor: AppColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color:
                  value ? Colors.black : Colors.grey, // Изменение цвета текста
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
