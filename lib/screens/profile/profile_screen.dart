import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nerobot/components/list/profile_list.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? role; // worker | customer
  bool isLoading = true;

  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  // ------------------------- Загрузка роли из Firestore --------------------
  Future<void> _loadUserRole() async {
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    setState(() {
      role = doc.data()?['type'] ?? 'customer';
      isLoading = false;
    });
  }

  // --------------------------- Обновление роли -----------------------------
  Future<void> _updateRole(String newRole) async {
    if (uid == null || (newRole != 'worker' && newRole != 'customer')) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'type': newRole,
    });

    setState(() => role = newRole);
  }

  // --------------------------- Выход из аккаунта ---------------------------
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) AutoRouter.of(context).replace(const WelcomeRoute());
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
                  subtitle: 'Супер (Топ-10)',
                  onTap: () => AutoRouter.of(context).push(ProfileStarsRoute()),
                ),
                ProfileOption(
                  title: 'Уведомления',
                  subtitle: 'Включены',
                  onTap:
                      () =>
                          AutoRouter.of(context).push(const ProfileNoteRoute()),
                ),
                ProfileOption(
                  title: 'Подписка',
                  subtitle: 'Истечёт через: 3 мес',
                  onTap:
                      () => AutoRouter.of(
                        context,
                      ).push(ProfileSubscriptionRoute()),
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
