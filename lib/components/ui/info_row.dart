import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool hasTopBorder;
  final bool hasBottomBorder;
  final bool isValueBelow; // Новый параметр

  const InfoRow({
    Key? key,
    required this.label,
    required this.value,
    this.hasTopBorder = false,
    this.hasBottomBorder = false,
    this.isValueBelow = false, // По умолчанию значение отображается справа
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Border border = Border(
      top:
          hasTopBorder
              ? BorderSide(width: 1, color: AppColors.border)
              : BorderSide.none,
      bottom:
          hasBottomBorder
              ? BorderSide(width: 1, color: AppColors.border)
              : BorderSide.none,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(border: border),
      child:
          isValueBelow
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4), // Отступ между `label` и `value`
                  Text(value, style: const TextStyle(fontSize: 14)),
                ],
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(value, style: const TextStyle(fontSize: 14)),
                ],
              ),
    );
  }
}
