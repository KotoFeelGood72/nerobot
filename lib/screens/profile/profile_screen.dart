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
      // Загружаем данные пользователя
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();

      // Загружаем активную подписку
      final subscription = await SubscriptionUtils.getActiveSubscription(uid!);

      // Локально сохраненная роль (на случай, если в БД нет типа)
      final savedRole = await RoleManager.getRole();

      print('DEBUG: Загружена подписка: ${subscription?.status}');
      print('DEBUG: Подписка активна: ${subscription?.isActive}');

      setState(() {
        role =
            (data?['type'] as String?) ??
            savedRole ??
            'worker'; // По умолчанию исполнитель
        notifCandidate =
            data?['notificationPreferences']?['candidate'] ?? false;
        notifCityTask = data?['notificationPreferences']?['cityTask'] ?? false;
        activeSubscription = subscription;
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных пользователя: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // --------------------------- Обновление роли -----------------------------
  Future<void> _updateRole(String newRole) async {
    if (uid == null || (newRole != 'worker' && newRole != 'customer')) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'type': newRole,
    });

    // Сохраняем локально, чтобы роль не «пропадала» без сети
    await RoleManager.saveRole(newRole);
    setState(() => role = newRole);
  }

  // --------------------------- Выход из аккаунта ---------------------------
  Future<void> _signOut() async {
    // Очищаем сохраненную роль при выходе
    await RoleManager.clearRole();
    await FirebaseAuth.instance.signOut();
    if (mounted) AutoRouter.of(context).replace(const WelcomeRoute());
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadUserData();
  }

  Future<void> _forceRefreshData() async {
    setState(() {
      isLoading = true;
    });

    // Принудительно очищаем кэш и загружаем данные заново
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadUserData();
  }

  String get notificationSubtitle {
    if (notifCandidate == true || notifCityTask == true) {
      return 'Включены';
    }
    return 'Выключены';
  }

  String get subscriptionSubtitle {
    if (activeSubscription == null) {
      return 'Нет активной подписки';
    }
    if (activeSubscription!.status == 'cancelled') {
      return 'Подписка отменена';
    }
    if (!activeSubscription!.isActive) {
      return 'Подписка истекла';
    }
    return 'Истечёт через: ${activeSubscription!.remainingTimeText}';
  }

  // -------------------------------------------------------------------------
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
            onPressed: _loadUserData,
            tooltip: 'Обновить',
          ),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 16),

          // ---------------------------- переключатель роли -----------------
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
                  // ----------- worker ------------
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _updateRole('worker'),
                      child: _roleChip(
                        active: role == 'worker',
                        label: 'Я — исполнитель',
                      ),
                    ),
                  ),
                  // ---------- customer -----------
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

          // --------------------------- прочие пункты ------------------------
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
                    if (result == true) {
                      _loadUserData();
                    }
                  },
                ),
                ProfileOption(
                  title: 'Подписка',
                  subtitle: subscriptionSubtitle,
                  onTap: () async {
                    final result = await AutoRouter.of(
                      context,
                    ).push(ProfileSubscriptionRoute());
                    // Всегда обновляем данные при возврате из экрана подписки
                    _loadUserData();
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

          // ------------------------------- выход ----------------------------
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

  // ------------------------- util: «чип» роли ------------------------------
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
