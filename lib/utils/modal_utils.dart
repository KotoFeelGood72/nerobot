import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

/// Глобальная функция для отображения кастомного ModalBottomSheet
Future<T?> showCustomModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool scroll = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: AppColors.bg,
    isScrollControlled: scroll,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(16.0), // Скругленные углы
      ),
    ),
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Полоса (гребень)
          Container(
            margin: const EdgeInsets.only(top: 20, bottom: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          builder(context), // Переданный виджет
        ],
      );
    },
  );
}
