import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

/// Пилл-табы из профиля ЛК.
class PillTabs extends StatelessWidget {
  final List<String> titles;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const PillTabs({
    super.key,
    required this.titles,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.ulight,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(width: 1, color: AppColors.border),
      ),
      child: Row(
        children: List.generate(titles.length, (i) {
          final active = selectedIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    titles[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: active ? AppColors.violet : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
