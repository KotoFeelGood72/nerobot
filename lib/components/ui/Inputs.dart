import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
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
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.maxLength,
    this.isMultiline = false,
    this.onChanged, // Добавляем onChanged
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
          padding: padding, // Используем переданный padding
          decoration: BoxDecoration(
            color: appliedBackgroundColor,
            borderRadius: BorderRadius.circular(8),
            border:
                showErrorMessage
                    ? Border.all(color: AppColors.red)
                    : Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Для многострочного ввода
            children: [
              Expanded(
                child: TextField(
                  controller: effectiveController,
                  keyboardType:
                      isMultiline
                          ? TextInputType.multiline
                          : fieldType == 'number'
                          ? TextInputType
                              .number // Тип клавиатуры для чисел
                          : fieldType == 'phone'
                          ? TextInputType.phone
                          : TextInputType.text,
                  maxLines:
                      isMultiline ? 3 : 1, // Поддержка многострочного ввода
                  style: TextStyle(
                    color: appliedTextColor,
                    fontSize: fontSize ?? 14,
                  ),
                  inputFormatters: inputFormatters, // Применяем ограничители
                  decoration: InputDecoration(
                    hintText:
                        fieldType == 'phone'
                            ? '+7 (999) 999-99-99'
                            : fieldType == 'number'
                            ? 'Введите число'
                            : 'Введите текст',
                    hintStyle: TextStyle(
                      color: appliedTextColor.withOpacity(0.6),
                      fontSize: fontSize ?? 14,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: onChanged, // Вызываем переданную функцию
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
