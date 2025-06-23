import 'package:auto_route/auto_route.dart';
import 'package:nerobot/guards/auth_guard.dart';
import 'package:nerobot/router/app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  final _authGuard = AuthGuard();
  final _unAuthGuard = UnAuthGuard();

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes => [
    // Роуты для неавторизованных пользователей
    AutoRoute(
      page: WelcomeRoute.page,
      path: '/welcome',
      initial: true,
      guards: [_unAuthGuard],
    ),
    AutoRoute(page: AuthRoute.page, path: '/auth', guards: [_unAuthGuard]),
    AutoRoute(
      page: ConfirmRoute.page,
      path: '/confirm',
      guards: [_unAuthGuard],
    ),

    // Закрытые роуты — только для авторизованных
    AutoRoute(page: TaskRoute.page, path: '/task', guards: [_authGuard]),
    AutoRoute(
      page: NewTaskCreateRoute.page,
      path: '/task/new',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: NewDescRoute.page,
      path: '/task/new/description',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: NewConfirmTaskRoute.page,
      path: '/task/new/confirm',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: TaskDetailRoute.page,
      path: '/task/detail/:taskId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: TaskDetailCustomerRoute.page,
      path: '/task/detail/:taskId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: TaskResponseRoute.page,
      path: '/task/response/:taskId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ChatsRoute.page,
      path: '/task/chats/:chatsId',
      guards: [_authGuard],
    ),

    AutoRoute(
      page: TaskCustomerProfileRoute.page,
      path: '/profile/customer/preview/:profileCustomerId',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileStarsRoute.page,
      path: '/profile/stars',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileFeedbackRoute.page,
      path: '/profile/faq/feedback',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileSubscriptionRoute.page,
      path: '/profile/subscription',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileHistoryPriceRoute.page,
      path: '/profile/history',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileHelpRoute.page,
      path: '/profile/help',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileAppRoute.page,
      path: '/profile/app',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileNoteRoute.page,
      path: '/profile/notifications',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileEditRoute.page,
      path: '/profile/edit',
      guards: [_authGuard],
    ),
    AutoRoute(
      page: ProfileUserDataRoute.page,
      path: '/profile/user',
      guards: [_authGuard],
    ),
    AutoRoute(page: VacansyRoute.page, path: '/vacancy', guards: [_authGuard]),
    AutoRoute(
      page: VacansyDetailRoute.page,
      path: '/vacancy/:id',
      guards: [_authGuard],
    ),
    AutoRoute(page: ProfileRoute.page, path: '/profile', guards: [_authGuard]),
  ];
}
