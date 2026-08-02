import 'dart:async'; // для unawaited()
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/list/profile_list.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/pill_tabs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/role_manager.dart';
import 'package:nerobot/utils/push_token_manager.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? role; // worker | customer
  bool isLoading = true;

  bool notificationsEnabled = true;

  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (uid == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      final savedRole = await RoleManager.getRole();

      final prefs = await PushTokenManager.loadPreferences();

      setState(() {
        role = (data?['type'] as String?) ?? savedRole ?? 'worker';
        notificationsEnabled = prefs.values.any((enabled) => enabled);
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      setState(() => isLoading = false);
    }
  }

  // мгновенное переключение роли
  Future<void> _updateRole(String newRole) async {
    if (uid == null || (newRole != 'worker' && newRole != 'customer')) return;

    // ⚡ Мгновенно обновляем UI
    setState(() => role = newRole);
    await RoleManager.saveRole(newRole);

    // 🕓 Обновляем Firestore в фоне (не блокируя интерфейс)
    unawaited(
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'type': newRole,
      }).then((_) async {
        final snap =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        await PushTokenManager.syncTopicsFromUserData(snap.data());
      }),
    );
  }

  // выход
  Future<void> _signOut() async {
    await RoleManager.clearRole();
    await FirebaseAuth.instance.signOut();
    if (mounted) AutoRouter.of(context).replace(const WelcomeRoute());
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    await _loadUserData();
  }

  String get notificationSubtitle =>
      notificationsEnabled ? 'Включены' : 'Выключены';

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Аккаунт',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Обновить',
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
        children: [
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: PillTabs(
              titles: const ['Я — исполнитель', 'Я — заказчик'],
              selectedIndex: role == 'customer' ? 1 : 0,
              onChanged: (i) => _updateRole(i == 0 ? 'worker' : 'customer'),
            ),
          ),

          const SizedBox(height: 16),

          // список
          Expanded(
            child: ProfileList(
              options: [
                ProfileOption(
                  title: 'Личные данные',
                  onTap:
                      () => AutoRouter.of(context).push(ProfileUserDataRoute()),
                ),
                ProfileOption(
                  title: 'Рейтинг и отзывы',
                  onTap: () => AutoRouter.of(context).push(ProfileStarsRoute()),
                ),
                ProfileOption(
                  title: 'Уведомления',
                  subtitle: notificationSubtitle,
                  onTap: () async {
                    final result = await AutoRouter.of(
                      context,
                    ).push(const ProfileNoteRoute());
                    if (result == true) _loadUserData();
                  },
                ),
                ProfileOption(
                  title: 'О приложении',
                  onTap:
                      () =>
                          AutoRouter.of(context).push(const ProfileAppRoute()),
                ),
                ProfileOption(
                  title: 'Помощь',
                  onTap: () => AutoRouter.of(context).push(ProfileHelpRoute()),
                ),
              ],
            ),
          ),

          // кнопка выхода
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Btn(
              text: 'Выйти',
              onPressed: _signOut,
              theme: 'secondary',
              textColor: AppColors.red,
            ),
          ),

          const Square(height: 16),
        ],
        ),
      ),
    );
  }

}
