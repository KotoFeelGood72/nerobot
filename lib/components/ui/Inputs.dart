import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:nerobot/components/ui/app_form_field.dart';
import 'package:nerobot/constants/app_colors.dart';

class Inputs extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final IconData? rightIcon;
  final String value;
  final TextEditingController? controller;
  final String? errorMessage;
  final bool showErrorMessage;
  final String fieldType;
  final String? label;
  final bool required;
  final EdgeInsetsGeometry padding;
  final int? maxLength;
  final bool isMultiline;
  final ValueChanged<String>? onChanged;
  final double? fontSize;

  const Inputs({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    this.rightIcon,
    this.value = '',
    this.controller,
    this.errorMessage,
    this.showErrorMessage = false,
    this.fieldType = 'text',
    this.label,
    this.required = false,
    this.padding = AppFormMetrics.controlPadding,
    this.maxLength,
    this.isMultiline = false,
    this.onChanged,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    // Создаем контроллер с маской, если поле для телефона
    TextEditingController effectiveController;
    if (controller != null) {
      effectiveController = controller!;
    } else if (fieldType == 'phone') {
      effectiveController = MaskedTextController(mask: '+7 (000) 000-00-00');
      effectiveController.text = value;
    } else {
      effectiveController = TextEditingController(text: value);
    }

    final Color appliedBackgroundColor =
        showErrorMessage ? Colors.red[50]! : backgroundColor;
    final Color appliedTextColor = showErrorMessage ? AppColors.red : textColor;

    // Устанавливаем inputFormatters в зависимости от fieldType
    List<TextInputFormatter> inputFormatters = [];
    if (fieldType == 'number') {
      inputFormatters = [
        FilteringTextInputFormatter.digitsOnly,
      ]; // Только цифры
    }
    if (maxLength != null) {
      inputFormatters.add(
        LengthLimitingTextInputFormatter(maxLength),
      ); // Ограничение символов
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) // Отображаем метку, если она задана
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Text(
                  label!,
                  style: TextStyle(
                    color: appliedTextColor,
                    fontSize: fontSize ?? 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (required) // Отображаем звездочку, если поле обязательное
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: isMultiline ? null : AppFormMetrics.controlHeight,
          padding: padding,
          alignment: isMultiline ? Alignment.topLeft : Alignment.center,
          decoration: BoxDecoration(
            color: appliedBackgroundColor,
            borderRadius: BorderRadius.circular(AppFormMetrics.radius),
            border:
                showErrorMessage
                    ? Border.all(color: AppColors.red)
                    : Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment:
                isMultiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: effectiveController,
                  keyboardType:
                      isMultiline
                          ? TextInputType.multiline
                          : fieldType == 'number'
                          ? TextInputType.number
                          : fieldType == 'phone'
                          ? TextInputType.phone
                          : fieldType == 'email'
                          ? TextInputType.emailAddress
                          : TextInputType.text,
                  obscureText: fieldType == 'password',
                  maxLines: isMultiline ? 3 : 1,
                  style: TextStyle(
                    color: appliedTextColor,
                    fontSize: fontSize ?? 14,
                  ),
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText:
                        fieldType == 'phone'
                            ? '+7 (999) 999-99-99'
                            : fieldType == 'number'
                            ? 'Введите число'
                            : fieldType == 'email'
                            ? 'example@mail.ru'
                            : fieldType == 'password'
                            ? 'Минимум 6 символов'
                            : 'Введите текст',
                    hintStyle: TextStyle(
                      color: appliedTextColor.withValues(alpha: 0.6),
                      fontSize: fontSize ?? 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: isMultiline ? 8 : 0,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (rightIcon != null) Icon(rightIcon, color: appliedTextColor),
            ],
          ),
        ),
        if (showErrorMessage && errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              errorMessage!,
              style: const TextStyle(color: AppColors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
