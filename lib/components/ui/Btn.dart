import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

/// Кнопки приложения.
///
/// Themes:
/// - `violet` / `primary` — primary (заливка violet, белый текст)
/// - `light` / `white` / `secondary` — secondary (светлый фон, violet текст)
class Btn extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String theme;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool disabled;

  const Btn({
    super.key,
    required this.text,
    this.onPressed,
    this.theme = 'secondary',
    this.textColor,
    this.borderRadius = 100,
    this.padding = const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
    this.disabled = false,
  });

  bool get _isPrimary => theme == 'violet' || theme == 'primary';

  Color get _backgroundColor {
    if (disabled) {
      return _isPrimary ? AppColors.violet.withValues(alpha: 0.4) : Colors.grey.shade200;
    }
    return _isPrimary ? AppColors.violet : AppColors.ulight;
  }

  Color get _labelColor {
    if (disabled) {
      return _isPrimary ? Colors.white70 : Colors.grey.shade500;
    }
    if (textColor != null) return textColor!;
    return _isPrimary ? Colors.white : AppColors.violet;
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _isPrimary ? 0.12 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding,
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _labelColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
