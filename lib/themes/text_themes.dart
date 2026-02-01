import 'package:flutter/material.dart';
import 'package:nerobot/constants/app_colors.dart';

TextTheme buildTextTheme() {
  return const TextTheme(
    headlineSmall: TextStyle(
      fontSize: 32.0,
      fontWeight: FontWeight.bold,
      color: AppColors.black,
    ),
    headlineMedium: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: AppColors.black,
    ),
    headlineLarge: TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.bold,
      color: AppColors.black,
    ),
    bodyLarge: TextStyle(fontSize: 16.0, color: AppColors.black),
    bodyMedium: TextStyle(fontSize: 14.0, color: AppColors.black),
    bodySmall: TextStyle(fontSize: 12.0, color: AppColors.black),
  );
}
