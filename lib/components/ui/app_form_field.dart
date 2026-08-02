import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

/// Общие метрики для инпутов, селектов и field-like контролов.
class AppFormMetrics {
  static const double controlHeight = 48;
  static const double radius = 8;
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(horizontal: 12);
}

/// Единый dropdown в стиле [Inputs].
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final double fontSize;
  final Color? backgroundColor;
  final Color iconColor;

  const AppDropdown({
    super.key,
    required this.items,
    this.value,
    this.hint,
    this.onChanged,
    this.fontSize = 14,
    this.backgroundColor,
    this.iconColor = AppColors.gray,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppFormMetrics.controlHeight,
      padding: AppFormMetrics.controlPadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.ulight,
        borderRadius: BorderRadius.circular(AppFormMetrics.radius),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: Icon(Icons.arrow_drop_down, color: iconColor),
          hint: hint == null
              ? null
              : Text(
                  hint!,
                  style: TextStyle(
                    color: AppColors.gray,
                    fontSize: fontSize,
                  ),
                ),
          style: TextStyle(color: AppColors.black, fontSize: fontSize),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
