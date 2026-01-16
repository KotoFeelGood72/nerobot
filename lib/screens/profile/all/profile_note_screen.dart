import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:nerobot/components/ui/Btn.dart';
import 'package:nerobot/constants/app_colors.dart';

@RoutePage()
class ProfileNoteScreen extends StatefulWidget {
  const ProfileNoteScreen({super.key});

  @override
  _ProfileNoteScreenState createState() => _ProfileNoteScreenState();
}

class _ProfileNoteScreenState extends State<ProfileNoteScreen> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isCandidateEnabled = true;
  bool _isCityTaskEnabled = false;
  bool _isLoading = true; // показываем крутилку, пока грузим

  @override
  void initState() {
    super.initState();
    debugPrint(">>> initState: старт инициализации уведомлений");
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    debugPrint(">>> _initializeNotifications(): запрошены разрешения...");
    try {
      // 1) Запрос разрешений
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint(
        ">>> requestPermission returned: ${settings.authorizationStatus}",
      );

      // 2) Проверяем currentUser
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint(">>> currentUser == null, отменяем дальнейшую загрузку");
        setState(() => _isLoading = false);
        return;
      }
      final uid = user.uid;
      debugPrint(">>> Пользователь залогинен, uid = $uid");

      // 3) Забираем FCM-токен
      final fcmToken = await _messaging.getToken();
      debugPrint(">>> Получили FCM token: $fcmToken");
      if (fcmToken != null) {
        debugPrint(
          ">>> Запускаем runTransaction для записи токена в Firestore...",
        );
        // Если транзакция внутри падает, мы это увидим в catch ниже
        await _firestore.runTransaction((tx) async {
          final userDocRef = _firestore.collection('users').doc(uid);
          final snapshot = await tx.get(userDocRef);
          if (snapshot.exists) {
            final data = snapshot.data()!;
            final List<dynamic> tokens = data['device_tokens'] ?? [];
            if (!tokens.contains(fcmToken)) {
              tokens.add(fcmToken);
              tx.update(userDocRef, {'device_tokens': tokens});
              debugPrint(">>> Токен добавлен в массив device_tokens");
            } else {
              debugPrint(">>> Токен уже присутствует в массиве");
            }
          } else {
            debugPrint(">>> Документа нет, создаём новый и добавляем token...");
            tx.set(userDocRef, {
              'device_tokens': [fcmToken],
            }, SetOptions(merge: true));
          }
        });
        debugPrint(">>> runTransaction успешно отработал");
      } else {
        debugPrint(">>> getToken() вернул null, пропускаем запись токена");
      }

      // 4) Загружаем сохранённые настройки из Firestore
      debugPrint(">>> Начинаем _loadSavedPreferencesFromFirestore");
      await _loadSavedPreferencesFromFirestore(uid);
      debugPrint(">>> _loadSavedPreferencesFromFirestore завершился");
    } catch (e, stack) {
      debugPrint("!!! Exception в _initializeNotifications: $e");
      debugPrint(stack.toString());
    } finally {
      // 5) В любом случае сбрасываем флаг загрузки
      debugPrint(
        ">>> Установка _isLoading = false, скрываем ProgressIndicator",
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSavedPreferencesFromFirestore(String uid) async {
    debugPrint(
      "    → _loadSavedPreferencesFromFirestore: получаем документ пользователя",
    );
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (!docSnapshot.exists) {
        debugPrint(
          "    → Документ отсутствует, создаём его с дефолтными prefs",
        );
        await _firestore.collection('users').doc(uid).set({
          'notificationPreferences': {
            'candidate': _isCandidateEnabled,
            'cityTask': _isCityTaskEnabled,
          },
        }, SetOptions(merge: true));

        // Подписываемся на топики дефолтно
        if (_isCandidateEnabled) {
          await _messaging.subscribeToTopic('candidate');
          debugPrint("    → Подписались на topic: candidate (дефолт)");
        }
        if (_isCityTaskEnabled) {
          await _messaging.subscribeToTopic('city_task');
          debugPrint("    → Подписались на topic: city_task (дефолт)");
        }
        return;
      }

      final data = docSnapshot.data()!;
      debugPrint("    → Документ существует, data = $data");
      final Map<String, dynamic> prefs =
          (data['notificationPreferences'] as Map<String, dynamic>?) ?? {};

      _isCandidateEnabled = prefs['candidate'] as bool? ?? _isCandidateEnabled;
      _isCityTaskEnabled = prefs['cityTask'] as bool? ?? _isCityTaskEnabled;
      debugPrint(
        "    → Из Firestore взяли prefs: candidate=$_isCandidateEnabled, cityTask=$_isCityTaskEnabled",
      );

      // Подписка/отписка от топиков
      if (_isCandidateEnabled) {
        await _messaging.subscribeToTopic('candidate');
        debugPrint("    → Подписались на topic: candidate");
      } else {
        await _messaging.unsubscribeFromTopic('candidate');
        debugPrint("    → Отписались от topic: candidate");
      }

      if (_isCityTaskEnabled) {
        await _messaging.subscribeToTopic('city_task');
        debugPrint("    → Подписались на topic: city_task");
      } else {
        await _messaging.unsubscribeFromTopic('city_task');
        debugPrint("    → Отписались от topic: city_task");
      }
    } catch (e, stack) {
      debugPrint("    !!! Ошибка в _loadSavedPreferencesFromFirestore: $e");
      debugPrint(stack.toString());
      // Решаем, как поступить: можно перезаписать дефолтными значениями,
      // либо просто вернуть, чтобы не блокировать UI.
      // Пока просто возвращаемся (если нужно— можно установить дефолт).
      return;
    }
  }

  Future<void> _updatePreferenceAndTopic({
    required String fieldName,
    required bool enabled,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint(">>> _updatePreferenceAndTopic: currentUser == null, выходим");
      return;
    }
    final uid = user.uid;
    final userDocRef = _firestore.collection('users').doc(uid);

    // 1) Обновляем Firestore
    try {
      await userDocRef.set({
        'notificationPreferences': {fieldName: enabled},
      }, SetOptions(merge: true));
      debugPrint(
        ">>> Preference '$fieldName' установлено = $enabled в Firestore",
      );
    } catch (e) {
      debugPrint("!!! Ошибка при обновлении pref в Firestore: $e");
    }

    // 2) Подписаться/отписаться от топика
    try {
      if (fieldName == 'candidate') {
        if (enabled) {
          await _messaging.subscribeToTopic('candidate');
          debugPrint(">>> Subscribe to topic: candidate");
        } else {
          await _messaging.unsubscribeFromTopic('candidate');
          debugPrint(">>> Unsubscribe from topic: candidate");
        }
      } else if (fieldName == 'cityTask') {
        if (enabled) {
          await _messaging.subscribeToTopic('city_task');
          debugPrint(">>> Subscribe to topic: city_task");
        } else {
          await _messaging.unsubscribeFromTopic('city_task');
          debugPrint(">>> Unsubscribe from topic: city_task");
        }
      }
    } catch (e) {
      debugPrint("!!! Ошибка при подписке/отписке от топика '$fieldName': $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Здесь мы видим спиннер, пока _isLoading == true
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSwitchTile(
              title: 'В списке кандидатов',
              value: _isCandidateEnabled,
              onChanged: (value) {
                setState(() => _isCandidateEnabled = value);
                _updatePreferenceAndTopic(
                  fieldName: 'candidate',
                  enabled: value,
                );
              },
            ),
            _buildSwitchTile(
              title: 'Задания в моём городе',
              value: _isCityTaskEnabled,
              onChanged: (value) {
                setState(() => _isCityTaskEnabled = value);
                _updatePreferenceAndTopic(
                  fieldName: 'cityTask',
                  enabled: value,
                );
              },
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Включите push-уведомления, чтобы узнавать о новых событиях',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: Btn(
                text: 'Сохранить изменения',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Настройки уведомлений сохранены'),
                    ),
                  );
                },
                theme: 'light',
                textColor: AppColors.violet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: value ? Colors.black : Colors.grey,
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }
}
