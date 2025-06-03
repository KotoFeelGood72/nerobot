import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Divider.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/clean_phone.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = MaskedTextController(mask: '+7 (000) 000-00-00');
  bool isButtonEnabled = false;
  bool isLoading = false;
  String? verificationId;

  @override
  void initState() {
    super.initState();
    _saveDeviceToken();
  }

  void _saveDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('FCM Token: $token');
    // Сохрани, если нужно
  }

  Future<void> _requestCode() async {
    final phoneNumber = CleanPhone.cleanPhoneNumber(_controller.text);

    final role = widget.role;

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        debugPrint('✅ Авто-вход выполнен');
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Ошибка подтверждения: ${e.message}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Ошибка авторизации')),
        );
        setState(() => isLoading = false);
      },
      codeSent: (String id, int? token) {
        setState(() {
          verificationId = id;
          isLoading = false;
        });
        AutoRouter.of(
          context,
        ).push(ConfirmRoute(verificationId: id, role: role));
      },
      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return EmptyLayout(
      title: 'Вход',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Inputs(
              controller: _controller,
              backgroundColor: AppColors.ulight,
              textColor: Colors.black,
              errorMessage: 'Поле обязательно для заполнения',
              fieldType: 'phone',
              onChanged: (value) {
                setState(() {
                  isButtonEnabled = value.length == 18;
                });
              },
            ),
            const Square(),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                  width: double.infinity,
                  child: Btn(
                    text: 'Выслать код',
                    onPressed: isButtonEnabled ? _requestCode : null,
                    theme: 'violet',
                    disabled: !isButtonEnabled,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
