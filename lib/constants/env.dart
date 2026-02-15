import 'package:flutter/foundation.dart';

/// true = вход по SMS или по тестовому номеру из Firebase Console (Authentication → Phone → Phone numbers for testing).
const bool useRealPhoneAuth = true;

/// В dev при вводе любого номера пускаем без SMS (анонимный вход). Если useRealPhoneAuth == true — всегда по номеру/SMS.
const bool devAuthBypass = kDebugMode && !useRealPhoneAuth;

/// true = отключить верификацию приложения (APNs/reCAPTCHA) для Phone Auth. Работают ТОЛЬКО тестовые номера из Firebase Console.
/// Убирает ошибку "reCAPTCHA SDK is not linked" на iOS без настройки APNs. Только для отладки.
const bool forcePhoneAuthTestingMode = kDebugMode && true;

/// Для прохождения App Review (iOS): в Firebase Console → Authentication → Sign-in method → Phone →
/// "Phone numbers for testing" добавь тестовый номер (напр. +1 650 555 1234, код 123456).
/// В App Store Connect → App Review Information → Notes укажи: "Вход: номер +1 650 555 1234, код 123456."
