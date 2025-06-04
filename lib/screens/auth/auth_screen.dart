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
import 'package:nerobot/utils/clean_phone.dart';

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
          // например, сразу можно сохранить номер:
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
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),

      verificationCompleted: (PhoneAuthCredential credential) async {
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
        // Переходим на экран ввода кода, передаём verificationId:
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
