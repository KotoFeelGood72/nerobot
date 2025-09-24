import 'package:auto_route/auto_route.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:nerobot/utils/auth_limits.dart';
import 'package:nerobot/utils/clean_phone.dart';
import 'package:nerobot/utils/phone_auth_helper.dart';
import 'package:nerobot/utils/firebase_test.dart';
import 'package:nerobot/utils/firebase_debug.dart';

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
  int retryCount = 0;

  @override
  void initState() {
    super.initState();
    // Убираем вызов _saveDeviceToken из initState:
    // _saveDeviceToken();
  }

  /// Вызывается после того, как мы точно знаем, что пользователь залогинен.
  Future<void> _saveDeviceToken() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('Пользователь ещё не залогинен, токен не сохраняем');
      return;
    }

    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snapshot = await tx.get(userRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        final List<dynamic> existingTokens = data['device_tokens'] ?? [];
        if (!existingTokens.contains(fcmToken)) {
          existingTokens.add(fcmToken);
          tx.update(userRef, {'device_tokens': existingTokens});
        }
      } else {
        // Если документа нет, создаём новый со всеми полями
        tx.set(userRef, {
          'device_tokens': [fcmToken],
          'type': widget.role,
          'created_date': DateTime.now().millisecondsSinceEpoch,
          'subscription_status': false,
          'subscription_days': 10,
          'phone': FirebaseAuth.instance.currentUser?.phoneNumber,
        }, SetOptions(merge: true));
      }
    });

    debugPrint('FCM-токен сохранён в Firestore');
  }

  Future<void> _requestCode() async {
    final phoneNumber = CleanPhone.cleanPhoneNumber(_controller.text);
    final role = widget.role;

    setState(() => isLoading = true);
    debugPrint('>>> Отправляем verifyPhone на номер: $phoneNumber');
    debugPrint('>>> Firebase project: handy-35312');
    debugPrint('>>> Package name: com.handywork.app');

    // Используем наш helper для принудительного использования нативной reCAPTCHA
    await PhoneAuthHelper.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      onVerificationCompleted: (PhoneAuthCredential credential) async {
        // Автоподстановка кода (Android), сразу логинимся:
        final userCred = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        debugPrint('✅ Авто-вход выполнен: UID=${userCred.user?.uid}');
        setState(() => isLoading = false);

        // После того как вход выполнился, сохраняем токен
        await _saveDeviceToken();

        // Можно сразу направить в нужный роут или домашний экран:
        // AutoRouter.of(context).replace(HomeRoute());
      },

      onVerificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Ошибка подтверждения: ${e.message}');
        debugPrint('❌ Код ошибки: ${e.code}');

        String errorMessage = 'Ошибка авторизации';

        // Специальная обработка для случаев с WebView reCAPTCHA
        if (e.code == 'web-context-cancelled' ||
            e.code == 'web-context-failed' ||
            e.message?.contains('webview') == true ||
            e.message?.contains('WebView') == true) {
          errorMessage = 'Ошибка с reCAPTCHA. Попробуйте еще раз';
        } else {
          switch (e.code) {
            case 'invalid-phone-number':
              errorMessage = 'Неверный номер телефона';
              break;
            case 'too-many-requests':
              errorMessage =
                  'Слишком много попыток. Попробуйте через несколько минут';
              // Сбрасываем счетчик попыток для возможности повторить позже
              retryCount = 0;
              break;
            case 'network-request-failed':
              errorMessage = 'Ошибка сети. Проверьте интернет-соединение';
              break;
            case 'captcha-check-failed':
              errorMessage = 'Ошибка reCAPTCHA. Попробуйте еще раз';
              break;
            case 'invalid-app-credential':
              errorMessage = 'Ошибка конфигурации приложения';
              break;
            default:
              errorMessage = e.message ?? 'Ошибка авторизации';
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        setState(() => isLoading = false);
      },

      onCodeSent: (String id, int? token) {
        setState(() {
          verificationId = id;
          isLoading = false;
        });
        // Переходим на экран ввода кода, передаём verificationId:
        AutoRouter.of(
          context,
        ).push(ConfirmRoute(verificationId: id, role: role));
      },

      onCodeAutoRetrievalTimeout: (String id) {
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
            const SizedBox(height: 16),
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
