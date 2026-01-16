import 'dart:async'; // для unawaited()
import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/list/profile_list.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/models/subscription.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/role_manager.dart';
import 'package:nerobot/utils/subscription_utils.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? role; // worker | customer
  bool isLoading = true;

  bool? notifCandidate;
  bool? notifCityTask;
  Subscription? activeSubscription;

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

      final subscription = await SubscriptionUtils.getActiveSubscription(uid!);
      final savedRole = await RoleManager.getRole();

      setState(() {
        role = (data?['type'] as String?) ?? savedRole ?? 'worker';
        notifCandidate =
            data?['notificationPreferences']?['candidate'] ?? false;
        notifCityTask = data?['notificationPreferences']?['cityTask'] ?? false;
        activeSubscription = subscription;
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

  String get notificationSubtitle {
    if (notifCandidate == true || notifCityTask == true) return 'Включены';
    return 'Выключены';
  }

  String get subscriptionSubtitle {
    if (activeSubscription == null) return 'Нет активной подписки';
    if (activeSubscription!.status == 'cancelled') return 'Подписка отменена';
    if (!activeSubscription!.isActive) return 'Подписка истекла';
    return 'Истечёт через: ${activeSubscription!.remainingTimeText}';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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

      body: Column(
        children: [
          const SizedBox(height: 16),

          // переключатель роли
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.ulight,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(width: 1, color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateRole('worker'),
                      child: _roleChip(
                        active: role == 'worker',
                        label: 'Я — исполнитель',
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateRole('customer'),
                      child: _roleChip(
                        active: role == 'customer',
                        label: 'Я — заказчик',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // список
          Expanded(
            child: ProfileList(
              options: [
                ProfileOption(
                  title: 'Личные данные',
                  onTap: () =>
                      AutoRouter.of(context).push(ProfileUserDataRoute()),
                ),
                ProfileOption(
                  title: 'Рейтинг и отзывы',
                  onTap: () => AutoRouter.of(context).push(ProfileStarsRoute()),
                ),
                ProfileOption(
                  title: 'Уведомления',
                  subtitle: notificationSubtitle,
                  onTap: () async {
                    final result = await AutoRouter.of(context)
                        .push(const ProfileNoteRoute());
                    if (result == true) _loadUserData();
                  },
                ),
                ProfileOption(
                  title: 'Подписка',
                  subtitle: subscriptionSubtitle,
                  onTap: () async {
                    await AutoRouter.of(context)
                        .push(ProfileSubscriptionRoute());
                    _loadUserData();
                  },
                ),
                ProfileOption(
                  title: 'О приложении',
                  onTap: () =>
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
          Btn(
            text: 'Выйти',
            onPressed: _signOut,
            theme: 'white',
            textColor: AppColors.red,
          ),

          const Square(height: 30),
        ],
      ),
    );
  }

  // компонент чипа роли
  Widget _roleChip({required bool active, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: active ? AppColors.violet : Colors.grey,
          ),
        ),
      ),
    );
  }
}