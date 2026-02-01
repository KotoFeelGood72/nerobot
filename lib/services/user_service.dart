import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  /// Возвращает true если создан/существует
  /// [phoneOverride] — для dev-входа без SMS (анонимный пользователь с «виртуальным» номером).
  static Future<bool> createUserIfNotExists(
    User user,
    String role, {
    String? phoneOverride,
  }) async {
    try {
      final uid = user.uid.trim();
      final ref = _db.collection('users').doc(uid);

      // Попробуем получить документ; используем retry/backoff при временных ошибках на уровне сети
      final doc = await ref.get();

      final phone = phoneOverride?.trim() ?? user.phoneNumber?.trim();
      if (!doc.exists) {
        await ref.set({
          'userId': uid, // обязательно, если правила требуют наличия userId
          'phone': phone,
          'type': role,
          'created_date': FieldValue.serverTimestamp(),
          'subscription_status': false,
          'subscription_days': 0,
          'name': 'Новый пользователь',
        }, SetOptions(merge: true));

        debugPrint('✅ createUserIfNotExists: created user $uid');
      } else {
        debugPrint('ℹ️ createUserIfNotExists: user already exists $uid');
      }
      return true;
    } on FirebaseException catch (e, st) {
      debugPrint('❌ createUserIfNotExists FIREBASE ERROR: ${e.code} ${e.message}\n$st');
      return false;
    } catch (e, st) {
      debugPrint('❌ createUserIfNotExists ERROR: $e\n$st');
      return false;
    }
  }
}