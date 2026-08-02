import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nerobot/utils/role_manager.dart';
import 'package:nerobot/utils/notification_constants.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static bool _isValidRole(String role) =>
      role == 'worker' || role == 'customer';

  /// Создаёт документ пользователя или обновляет роль/контакты при повторном входе.
  static Future<bool> createUserIfNotExists(
    User user,
    String role, {
    String? phoneOverride,
  }) async {
    try {
      final uid = user.uid.trim();
      final ref = _db.collection('users').doc(uid);
      final doc = await ref.get();

      final phone = phoneOverride?.trim() ?? user.phoneNumber?.trim();
      final email = user.email?.trim();
      final resolvedRole = _isValidRole(role) ? role : null;

      if (!doc.exists) {
        await ref.set({
          'userId': uid,
          'phone': phone,
          'email': email,
          'type': resolvedRole ?? 'worker',
          'created_date': FieldValue.serverTimestamp(),
          'name': 'Новый пользователь',
          'firstName': 'Новый',
          'lastName': 'пользователь',
          'notificationPreferences': NotificationPrefs.defaults,
        }, SetOptions(merge: true));
        debugPrint('✅ createUserIfNotExists: created user $uid');
      } else if (resolvedRole != null) {
        await ref.set({
          'type': resolvedRole,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        }, SetOptions(merge: true));
        debugPrint('✅ createUserIfNotExists: updated role for $uid → $resolvedRole');
      } else {
        debugPrint('ℹ️ createUserIfNotExists: user already exists $uid');
      }

      if (resolvedRole != null) {
        await RoleManager.saveRole(resolvedRole);
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
