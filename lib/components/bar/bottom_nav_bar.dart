import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

import 'package:nerobot/components/ui/Icons.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/router/app_router.gr.dart';

class BottomNavBar extends StatelessWidget {
  /// Показывать ли центральную кнопку «Создать заказ» (для заказчиков).
  final bool showCreateButton;

  static const double _barHeight = 48;

  const BottomNavBar({super.key, this.showCreateButton = false});

  @override
  Widget build(BuildContext context) {
    if (showCreateButton) {
      return _buildCustomBarWithCenterButton(context);
    }
    return _buildStandardBar(context);
  }

  Widget _buildBarShell({required Widget child}) {
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
        top: false,
        child: SizedBox(height: _barHeight, child: child),
      ),
    );
  }

  Widget _navItem({
    required String iconName,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconWidget(iconName: iconName, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBarWithCenterButton(BuildContext context) {
    return _buildBarShell(
      child: Row(
        children: [
          _navItem(
            iconName: 'case',
            label: 'Задания',
            color: AppColors.violet,
            onTap: () => context.router.push(const TaskRoute()),
          ),
          SizedBox(
            width: 56,
            child: Transform.translate(
              offset: const Offset(0, -10),
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
                    width: 48,
                    height: 48,
                    child: Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ),
          _navItem(
            iconName: 'settings',
            label: 'Аккаунт',
            color: AppColors.light,
            onTap: () => context.router.push(ProfileRoute()),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardBar(BuildContext context) {
    return _buildBarShell(
      child: Row(
        children: [
          _navItem(
            iconName: 'case',
            label: 'Задания',
            color: AppColors.violet,
            onTap: () => context.router.push(const TaskRoute()),
          ),
          _navItem(
            iconName: 'settings',
            label: 'Аккаунт',
            color: AppColors.light,
            onTap: () => context.router.push(ProfileRoute()),
          ),
        ],
      ),
    );
  }
}
