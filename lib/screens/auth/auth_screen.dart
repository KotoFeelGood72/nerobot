import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/email_auth_helper.dart';

@RoutePage()
class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();

  bool _isEmailValid = false;
  bool isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();

    if (!EmailAuthHelper.isValidEmail(email)) {
      _showError('Введите корректный email');
      return;
    }

    setState(() => isLoading = true);

    try {
      final debugCode = await EmailAuthHelper.sendOtp(email);
      if (!mounted) return;

      if (kDebugMode && debugCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug OTP: $debugCode'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      AutoRouter.of(context).push(
        ConfirmRoute(
          role: widget.role,
          email: email,
        ),
      );
    } catch (e, st) {
      debugPrint('❌ Email OTP send error: $e\n$st');
      _showError(EmailAuthHelper.mapError(e));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmptyLayout(
      title: 'Вход',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Inputs(
              controller: _emailController,
              backgroundColor: AppColors.ulight,
              textColor: Colors.black,
              fieldType: 'email',
              label: 'Email',
              onChanged: (value) {
                setState(
                  () => _isEmailValid = EmailAuthHelper.isValidEmail(value),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Мы отправим одноразовый код на вашу почту',
              style: TextStyle(color: AppColors.gray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: Btn(
                  text: 'Выслать код',
                  theme: 'primary',
                  onPressed: _isEmailValid ? _requestOtp : null,
                  disabled: !_isEmailValid,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
