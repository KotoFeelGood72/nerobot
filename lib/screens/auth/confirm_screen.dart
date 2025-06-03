import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';

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

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds == 0) {
        timer.cancel();
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
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Future<void> _resendCode() async {
    // Реализация повторной отправки кода — зависит от твоей логики
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Функция повторной отправки не реализована'),
      ),
    );
    setState(() {
      remainingSeconds = 60;
    });
    _startTimer();
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
              fieldWidth: 60,
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
              'Вы сможете запросить код через $remainingSeconds секунд',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Btn(
              disabled: remainingSeconds > 0,
              text: 'Выслать код ещё раз',
              theme: 'violet',
              onPressed: remainingSeconds > 0 ? null : _resendCode,
            ),
          ],
        ),
      ),
    );
  }
}
