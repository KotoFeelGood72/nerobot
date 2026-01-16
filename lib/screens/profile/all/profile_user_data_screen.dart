import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/info_row.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ProfileUserDataScreen extends StatefulWidget {
  const ProfileUserDataScreen({super.key});

  @override
  State<ProfileUserDataScreen> createState() => _ProfileUserDataScreenState();
}

class _ProfileUserDataScreenState extends State<ProfileUserDataScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // Проверяем mounted прежде чем вызывать setState
      if (!mounted) return;
      setState(() {
        error = "Пользователь не найден";
        isLoading = false;
      });
      return;
    }

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Сразу же проверяем mounted перед тем, как обновить состояние
      if (!mounted) return;

      if (doc.exists) {
        setState(() {
          userData = doc.data();
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Данные пользователя отсутствуют";
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Личные данные')),
        body: Center(child: Text('Ошибка: $error')),
      );
    }

    final photo = userData?['image_url'] ?? '';
    final firstName = userData?['firstName'] ?? '';
    final lastName = userData?['lastName'] ?? '';
    final phone = userData?['phone'] ?? '';
    final city = userData?['city'] ?? 'Не указан';
    final about =
        userData?['about'] ??
        'Для современного мира разбавленное изрядной долей эмпатии, рациональное мышление создаёт предпосылки для кластеризации усилий.';

    return Scaffold(
      appBar: AppBar(title: const Text('Личные данные')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    photo != ''
                        ? NetworkImage(photo)
                        : const AssetImage('assets/images/splash.png')
                            as ImageProvider,
              ),
            ),
            const Square(),
            Text(
              '$firstName $lastName',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            InfoRow(label: 'Телефон', value: phone, hasBottomBorder: true),
            InfoRow(label: 'Город', value: city, hasBottomBorder: true),
            SizedBox(
              width: double.infinity,
              child: InfoRow(
                label: 'О себе',
                value: about,
                hasBottomBorder: true,
                isValueBelow: true,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Редактировать',
                      onPressed: () async {
                        // ждем, пока экран редактирования закроется
                        await AutoRouter.of(
                          context,
                        ).push(const ProfileEditRoute());
                        // после возврата — обновляем данные
                        // Но опять же: обновляем только если mounted == true
                        if (!mounted) return;
                        _loadUserData();
                      },
                      theme: 'violet',
                    ),
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
