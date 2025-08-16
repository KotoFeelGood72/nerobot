import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
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
        // BottomNavigationBarItem(
        //   icon: IconWidget(iconName: 'credit', color: AppColors.gray, size: 25),
        //   label: 'Счёт',
        // ),
        BottomNavigationBarItem(
          icon: IconWidget(
            iconName: 'vacancy',
            color: AppColors.gray,
            size: 25,
          ),
          label: 'Вакансии',
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
          // case 1:
          //   context.router.push(ProfileRoute());
          //   break;
          case 1:
            context.router.push(const VacansyRoute());
            break;
          case 2:
            context.router.push(ProfileRoute());
            break;
        }
      },
    );
  }
}
