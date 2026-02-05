import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';

import 'package:nerobot/utils/subscription_utils.dart';
import 'package:nerobot/services/user_service.dart';

@RoutePage()
class ConfirmScreen extends StatefulWidget {
  final String verificationId;
  final String role;
  /// Номер, на который отправили код (для повторной отправки)
  final String phoneNumber;
  /// Токен для force resend (док: forceResendingToken). На iOS всегда null.
  final int? resendToken;

  const ConfirmScreen({
    super.key,
    required this.verificationId,
    required this.role,
    required this.phoneNumber,
    this.resendToken,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String? errorMessage;
  int remainingSeconds = 60;
  late Timer _timer;
  bool canResend = false;
  int resendCount = 0;
  /// Текущий verificationId (обновляется при resend).
  late String _verificationId;
  /// Токен для принудительной повторной отправки (по доке forceResendingToken).
  int? _resendToken;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  Future<void> _verify(String code) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );

      final userCred =
          await FirebaseAuth.instance.signInWithCredential(cred);

      final user = userCred.user;
      if (user == null) throw Exception("User is null");

      // Создаём юзера
      await UserService.createUserIfNotExists(user, widget.role);

      // Добавляем триал
      await SubscriptionUtils.ensureFreeTrial(user.uid);

      if (!mounted) return;
      AutoRouter.of(context).replaceAll([const TaskRoute()]);
    } on FirebaseAuthException catch (e) {
      String msg = 'Ошибка';

      switch (e.code) {
        case 'invalid-verification-code':
          msg = 'Неверный код';
          break;
        case 'session-expired':
          msg = 'Сессия истекла';
          break;
        default:
          msg = e.message ?? 'Ошибка';
      }

      setState(() => errorMessage = msg);
    }
  }

  Future<void> _resend() async {
    if (!canResend) return;

    _timer.cancel();
    setState(() {
      canResend = false;
      remainingSeconds = 60;
    });
    _startTimer();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      forceResendingToken: _resendToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Ошибка отправки кода')),
          );
        }
      },
      codeSent: (String newVerificationId, int? newResendToken) {
        if (!mounted) return;
        setState(() {
          _verificationId = newVerificationId;
          _resendToken = newResendToken;
          resendCount++;
          remainingSeconds = 60;
          canResend = false;
        });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EmptyLayout(
      title: 'Код подтверждения',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OtpTextField(
              numberOfFields: 6,
              borderColor: errorMessage != null ? Colors.red : AppColors.border,
              filled: true,
              fillColor: AppColors.ulight,
              onSubmit: (code) async => await _verify(code),
            ),
            const SizedBox(height: 12),

            if (errorMessage != null)
              Text(errorMessage!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            Text(
              canResend
                  ? "Можно отправить код повторно"
                  : "Запросить новый код через $remainingSeconds сек",
              style: TextStyle(
                color: canResend ? Colors.green : Colors.grey,
              ),
            ),

            const SizedBox(height: 12),

            Btn(
              text: "Отправить код ещё раз",
              disabled: !canResend,
              theme: 'violet',
              onPressed: canResend ? _resend : null,
            )
          ],
        ),
      ),
    );
  }
}
