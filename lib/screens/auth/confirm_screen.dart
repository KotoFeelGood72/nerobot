import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/services/user_service.dart';
import 'package:nerobot/utils/email_auth_helper.dart';
import 'package:nerobot/utils/push_token_manager.dart';

@RoutePage()
class ConfirmScreen extends StatefulWidget {
  final String role;
  final String email;

  const ConfirmScreen({
    super.key,
    required this.role,
    required this.email,
  });

  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen> {
  String? errorMessage;
  int remainingSeconds = 60;
  late Timer _timer;
  bool canResend = false;
  bool isLoading = false;
  String _code = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    canResend = false;
    remainingSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (remainingSeconds == 0) {
        setState(() => canResend = true);
        timer.cancel();
      } else {
        setState(() => remainingSeconds--);
      }
    });
  }

  /// Push-токен не должен ломать вход (на симуляторе APNS часто отсутствует).
  Future<void> _saveDeviceToken() => PushTokenManager.registerCurrentDevice();

  Future<void> _verify(String code) async {
    if (code.length != 6 || isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userCred = await EmailAuthHelper.verifyOtp(
        email: widget.email,
        code: code,
      );
      final user = userCred.user;
      if (user == null) throw Exception('User is null');

      final created = await UserService.createUserIfNotExists(user, widget.role);
      if (!created) {
        throw Exception('Не удалось создать профиль пользователя');
      }
      await _saveDeviceToken();

      if (!mounted) return;
      AutoRouter.of(context).replaceAll([const TaskRoute()]);
    } catch (e, st) {
      debugPrint('❌ Email OTP verify error: $e\n$st');
      if (!mounted) return;
      setState(() => errorMessage = EmailAuthHelper.mapError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resend() async {
    if (!canResend || isLoading) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final debugCode = await EmailAuthHelper.sendOtp(widget.email);
      if (!mounted) return;

      if (kDebugMode && debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug OTP: $debugCode'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _timer.cancel();
      _startTimer();
    } catch (e, st) {
      debugPrint('❌ Email OTP resend error: $e\n$st');
      if (!mounted) return;
      setState(() => errorMessage = EmailAuthHelper.mapError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmptyLayout(
      title: 'Подтверждение',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              'Код отправлен на ${widget.email}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gray),
            ),
            const SizedBox(height: 24),
            OtpTextField(
              numberOfFields: 6,
              fieldWidth: 48,
              fieldHeight: 56,
              borderColor: AppColors.border,
              focusedBorderColor: AppColors.violet,
              enabledBorderColor: AppColors.border,
              showFieldAsBox: true,
              borderRadius: BorderRadius.circular(10),
              borderWidth: 1.5,
              alignment: Alignment.center,
              contentPadding: EdgeInsets.zero,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.0,
                color: Colors.black,
              ),
              onCodeChanged: (value) {
                setState(() => _code = value);
              },
              onSubmit: _verify,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Btn(
                text: 'Подтвердить',
                theme: 'primary',
                onPressed: _code.length == 6 ? () => _verify(_code) : null,
                disabled: _code.length != 6,
              ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: canResend && !isLoading ? _resend : null,
              child: Text(
                canResend
                    ? 'Отправить код ещё раз'
                    : 'Повторная отправка через $remainingSeconds с',
                style: TextStyle(
                  color: canResend ? AppColors.violet : AppColors.gray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
