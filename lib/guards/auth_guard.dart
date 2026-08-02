import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nerobot/router/app_router.gr.dart';

class AuthGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (FirebaseAuth.instance.currentUser != null) {
      resolver.next();
    } else {
      resolver.redirect(const WelcomeRoute());
    }
  }
}

class UnAuthGuard extends AutoRouteGuard {
  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) {
      resolver.next();
    } else {
      resolver.redirect(const TaskRoute());
    }
  }
}
