import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nerobot/constants/app_colors.dart';

class IconWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;
  final String assetsPath;

  const IconWidget({
    super.key,
    required this.iconName,
    this.size = 24.0,
    this.color,
    this.assetsPath = 'assets/icons/',
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      '$assetsPath$iconName.svg',
      width: size,
      height: size,
      color: color ?? AppColors.black,
    );
  }
}
