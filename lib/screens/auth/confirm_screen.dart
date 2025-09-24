import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/auth_limits.dart';

@RoutePage()
class ConfirmScreen extends StatefulWidget {
  final String verificationId;
  final String role;

  const ConfirmScreen({
    super.key,
    required this.verificationId,
    required this.role,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String? errorMessage;
  int remainingSeconds = 60;
  late final Timer _timer;
  bool canResend = false;
  int resendCount = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
        setState(() {
          canResend = true;
        });
      } else {
        setState(() {
          remainingSeconds--;
        });
      }
    });
  }

  Future<void> _verifyCode(String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: smsCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      AutoRouter.of(context).replaceAll([TaskRoute()]);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Ошибка подтверждения кода: ${e.message}');
      debugPrint('❌ Код ошибки: ${e.code}');

      String errorText = 'Ошибка авторизации';

      switch (e.code) {
        case 'invalid-verification-code':
          errorText = 'Неверный код подтверждения';
          break;
        case 'invalid-verification-id':
          errorText = 'Неверный ID подтверждения. Попробуйте заново';
          break;
        case 'session-expired':
          errorText = 'Сессия истекла. Получите новый код';
          break;
        case 'network-request-failed':
          errorText = 'Ошибка сети. Проверьте интернет-соединение';
          break;
        default:
          errorText = e.message ?? 'Ошибка авторизации';
      }

      setState(() {
        errorMessage = errorText;
      });
    }
  }

  Future<void> _resendCode() async {
    if (!canResend || resendCount >= AuthLimits.maxResendAttempts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resendCount >= AuthLimits.maxResendAttempts
                ? 'Превышен лимит повторных отправок'
                : 'Подождите ${remainingSeconds} секунд',
          ),
        ),
      );
      return;
    }

    try {
      // Получаем номер телефона из текущего пользователя
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser?.phoneNumber == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось получить номер телефона')),
        );
        return;
      }

      // Повторно запрашиваем код
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: currentUser!.phoneNumber!,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Автоматический вход, если получилось
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (!mounted) return;
          AutoRouter.of(context).replaceAll([TaskRoute()]);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Ошибка повторной отправки: ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка отправки: ${e.message ?? "Неизвестная ошибка"}',
              ),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            remainingSeconds = 60;
            canResend = false;
            resendCount++;
          });
          _startTimer();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Код отправлен повторно')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Таймаут
        },
      );
    } catch (e) {
      debugPrint('❌ Ошибка при повторной отправке: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при повторной отправке кода')),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOtpError = errorMessage?.contains('Неверный код') ?? false;

    return EmptyLayout(
      title: 'Ввод кода',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OtpTextField(
              filled: true,
              fillColor: AppColors.ulight,
              numberOfFields: 6,
              borderColor: hasOtpError ? Colors.red : AppColors.border,
              borderWidth: 1,
              focusedBorderColor: hasOtpError ? Colors.red : AppColors.violet,
              showFieldAsBox: true,
              fieldWidth: 50,
              fieldHeight: 48,
              onSubmit: (code) async {
                if (code.length == 6) {
                  await _verifyCode(code);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Введите полный код!')),
                  );
                }
              },
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            const SizedBox(height: 12),
            if (hasOtpError)
              Text(
                errorMessage ?? 'Произошла ошибка',
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            Text(
              canResend
                  ? 'Можно запросить код повторно'
                  : 'Вы сможете запросить код через $remainingSeconds секунд',
              style: TextStyle(color: canResend ? Colors.green : Colors.grey),
            ),
            const SizedBox(height: 12),
            Btn(
              disabled:
                  !canResend || resendCount >= AuthLimits.maxResendAttempts,
              text:
                  resendCount >= AuthLimits.maxResendAttempts
                      ? 'Лимит повторных отправок исчерпан'
                      : 'Выслать код ещё раз (${resendCount}/${AuthLimits.maxResendAttempts})',
              theme: 'violet',
              onPressed:
                  (!canResend || resendCount >= AuthLimits.maxResendAttempts)
                      ? null
                      : _resendCode,
            ),
          ],
        ),
      ),
    );
  }
}
