import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

class Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String theme;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool disabled; // Добавляем параметр для состояния disabled

  const Btn({
    super.key,
    required this.text,
    this.onPressed,
    this.theme = 'yellow',
    this.textColor,
    this.borderRadius = 100.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    this.disabled = false, // Значение по умолчанию для disabled
  });

  // Метод для получения цвета фона в зависимости от темы и состояния disabled
  Color _getBackgroundColor() {
    if (disabled) return Colors.grey.shade400; // Цвет для disabled состояния
    switch (theme) {
      case 'light':
        return AppColors.ulight;
      case 'violet':
        return AppColors.violet;
      case 'white':
        return AppColors.white;
      case 'red':
        return AppColors.red;
      case 'yellow':
      default:
        return AppColors.yellow;
    }
  }

  // Метод для получения цвета текста в зависимости от темы и состояния disabled
  Color _getTextColor() {
    if (disabled)
      return Colors.grey.shade600; // Цвет текста для disabled состояния
    if (textColor != null) return textColor!;
    switch (theme) {
      case 'light':
        return AppColors.black;
      case 'violet':
        return AppColors.white;
      case 'yellow':
        return AppColors.white;
      case 'white':
        return AppColors.violet;
      default:
        return AppColors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: padding,
        backgroundColor: _getBackgroundColor(),
        elevation:
            (theme == 'white' || disabled)
                ? 0
                : null, // Убираем тень для disabled или white
        shadowColor:
            (theme == 'white' || disabled)
                ? Colors.transparent
                : null, // Убираем тень для disabled или white
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ).copyWith(
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (theme == 'white' || disabled)
            return Colors
                .transparent; // Убираем эффект нажатия для disabled или white
          return null;
        }),
      ),
      onPressed:
          disabled ? null : onPressed, // Блокируем нажатие, если disabled
      child: Text(text, style: TextStyle(color: _getTextColor(), fontSize: 16)),
    );
  }
}
