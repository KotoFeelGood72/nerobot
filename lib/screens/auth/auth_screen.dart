import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/components/ui/Inputs.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/layouts/empty_layout.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/clean_phone.dart';
import 'package:nerobot/utils/phone_auth_helper.dart';
import 'package:nerobot/services/user_service.dart';
import 'package:nerobot/utils/subscription_utils.dart';   // <<< не забудь добавить!

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

  /// Сохранение FCM токена
  Future<void> _saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);

    await ref.set({
      'device_tokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Отправляем код
  Future<void> _requestCode() async {
    final phone = CleanPhone.cleanPhoneNumber(_controller.text);

    setState(() => isLoading = true);

    await PhoneAuthHelper.startPhoneSignIn(
      phoneNumber: phone,

      /// <<< ВАЖНО: обработка автоматического подтверждения
      onVerificationCompleted: (credential) async {
        try {
          final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
          final user = userCred.user;
          if (user == null) throw Exception("User is null");

          final ok = await UserService.createUserIfNotExists(user, widget.role);
          debugPrint('createUserIfNotExists returned: $ok');

          await SubscriptionUtils.ensureFreeTrial(user.uid);
          debugPrint('ensureFreeTrial finished for ${user.uid}');

          await _saveDeviceToken();

          if (!mounted) return;
          AutoRouter.of(context).replaceAll([const TaskRoute()]);
        } catch (e, st) {
          debugPrint('❌ Auth -> post sign-in error: $e\n$st');
        } finally {
          if (mounted) setState(() => isLoading = false);
        }
      },

      onVerificationFailed: (e) {
        debugPrint("Ошибка phone auth: ${e.message}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Ошибка авторизации")),
        );
        setState(() => isLoading = false);
      },

      onCodeSent: (id, _) {
        setState(() {
          verificationId = id;
          isLoading = false;
        });

        AutoRouter.of(context).push(
          ConfirmRoute(
            verificationId: id,
            role: widget.role,
          ),
        );
      },

      onCodeAutoRetrievalTimeout: (id) {
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
              errorMessage: 'Введите номер',
              fieldType: 'phone',
              onChanged: (value) {
                setState(() {
                  isButtonEnabled = value.length == 18;
                });
              },
            ),
            const SizedBox(height: 16),
            isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    child: Btn(
                      text: 'Выслать код',
                      theme: 'violet',
                      onPressed: isButtonEnabled ? _requestCode : null,
                      disabled: !isButtonEnabled,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}