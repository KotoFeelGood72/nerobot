import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

/// Крупный thumb слайдера с подписью вида «18 км».
class RadiusSliderThumb extends SliderComponentShape {
  const RadiusSliderThumb({
    required this.value,
    this.height = 36,
    this.minWidth = 56,
  });

  final double value;
  final double height;
  final double minWidth;

  String get _label => '${value.round()} км';

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(minWidth + 8, height);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final textPainter = TextPainter(
      text: TextSpan(
        text: _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout();

    final width = (textPainter.width + 20).clamp(minWidth, 96.0);
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: width, height: height),
      Radius.circular(height / 2),
    );

    final shadowPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(rect.shift(const Offset(0, 1.5)), shadowPaint);

    final fillPaint = Paint()..color = sliderTheme.thumbColor ?? AppColors.violet;
    canvas.drawRRect(rect, fillPaint);

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}
