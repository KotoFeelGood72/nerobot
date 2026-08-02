import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:nerobot/router/app_router.dart';
import 'package:nerobot/router/app_router.gr.dart';
import 'package:nerobot/utils/email_auth_helper.dart';
import 'package:nerobot/utils/role_manager.dart';

/// Автопроход экранов для скриншотов стора.
class ScreenshotTour {
  // Временно всегда включено для генерации скриншотов.
  static const enabled = true;

  static const _email = 'test@raznorabochii.ru';
  static const _otp = '111111';

  static void schedule(AppRouter router) {
    if (!enabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('SCREENSHOT_TOUR_SCHEDULED');
      await Future<void>.delayed(const Duration(seconds: 4));
      try {
        await _run(router);
      } catch (e, st) {
        print('SCREENSHOT_TOUR_ERROR: $e');
        print('$st');
      }
    });
  }

  static Future<void> _mark(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    print('SCREENSHOT_MARK:$name');
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }

  static Future<void> _setRole(String role) async {
    await RoleManager.saveRole(role);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'type': role,
      }, SetOptions(merge: true));
    }
  }

  static Future<void> _run(AppRouter router) async {
    print('SCREENSHOT_TOUR_START');

    await FirebaseAuth.instance.signOut();
    await RoleManager.clearRole();
    router.replaceAll([const WelcomeRoute()]);
    await _mark('01_welcome');

    router.push(AuthRoute(role: 'worker'));
    await _mark('02_auth_email');

    await EmailAuthHelper.sendOtp(_email);
    router.push(ConfirmRoute(role: 'worker', email: _email));
    await _mark('03_auth_otp');

    await EmailAuthHelper.verifyOtp(email: _email, code: _otp);
    await _setRole('worker');
    router.replaceAll([const TaskRoute()]);
    await _mark('04_tasks_worker');

    router.push(const ProfileRoute());
    await _mark('05_profile');

    router.push(const ProfileUserDataRoute());
    await _mark('06_profile_user_data');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileStarsRoute());
    await _mark('07_profile_stars');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileNoteRoute());
    await _mark('08_profile_notifications');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileAppRoute());
    await _mark('09_profile_about');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileHelpRoute());
    await _mark('10_profile_help');

    router.push(const ProfileFeedbackRoute());
    await _mark('11_profile_feedback');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileTermsRoute());
    await _mark('12_profile_terms');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfilePrivacyRoute());
    await _mark('13_profile_privacy');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    router.push(const ProfileEditRoute());
    await _mark('14_profile_edit');
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await router.maybePop();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await _setRole('customer');
    router.replaceAll([const TaskRoute()]);
    await _mark('15_tasks_customer');

    router.push(const NewTaskCreateRoute());
    await _mark('16_task_create');

    print('SCREENSHOT_TOUR_DONE');
  }
}
