import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

class BottomNavBar extends StatelessWidget {
  /// Показывать ли центральную кнопку «Создать заказ» (для заказчиков).
  final bool showCreateButton;

  const BottomNavBar({super.key, this.showCreateButton = false});

  @override
  Widget build(BuildContext context) {
    if (showCreateButton) {
      return _buildCustomBarWithCenterButton(context);
    }
    return _buildStandardBar(context);
  }

  Widget _buildCustomBarWithCenterButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.router.push(const TaskRoute()),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconWidget(
                        iconName: 'case',
                        color: AppColors.violet,
                        size: 25,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Задания',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.violet,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Transform.translate(
                  offset: const Offset(0, -12),
                  child: Material(
                    color: AppColors.violet,
                    shape: const CircleBorder(),
                    elevation: 4,
                    shadowColor: AppColors.violet.withValues(alpha: 0.4),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          context.router.push(const NewTaskCreateRoute()),
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => context.router.push(ProfileRoute()),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconWidget(
                        iconName: 'settings',
                        color: AppColors.light,
                        size: 25,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Аккаунт',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.light,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardBar(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.white,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.violet,
      unselectedItemColor: AppColors.light,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: IconWidget(iconName: 'case', color: AppColors.gray, size: 25),
          activeIcon: IconWidget(
            iconName: 'case',
            color: AppColors.violet,
            size: 25,
          ),
          label: 'Задания',
        ),
        BottomNavigationBarItem(
          icon: IconWidget(
            iconName: 'settings',
            color: AppColors.gray,
            size: 25,
          ),
          label: 'Аккаунт',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.router.push(const TaskRoute());
            break;
          case 1:
            context.router.push(ProfileRoute());
            break;
        }
      },
    );
  }
}
