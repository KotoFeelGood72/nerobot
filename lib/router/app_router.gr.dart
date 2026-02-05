// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i28;
import 'package:flutter/material.dart' as _i29;
import 'package:nerobot/screens/auth/auth_screen.dart' as _i1;
import 'package:nerobot/screens/auth/confirm_screen.dart' as _i3;
import 'package:nerobot/screens/onboarding/onboarding_screen.dart' as _i5;
import 'package:nerobot/screens/profile/all/profile_app_screen.dart' as _i6;
import 'package:nerobot/screens/profile/all/profile_edit_screen.dart' as _i7;
import 'package:nerobot/screens/profile/all/profile_feedback_screen.dart'
    as _i8;
import 'package:nerobot/screens/profile/all/profile_help_screen.dart' as _i9;
import 'package:nerobot/screens/profile/all/profile_history_price_screen.dart'
    as _i10;
import 'package:nerobot/screens/profile/all/profile_note_screen.dart' as _i11;
import 'package:nerobot/screens/profile/all/profile_privacy_screen.dart'
    as _i12;
import 'package:nerobot/screens/profile/all/profile_stars_screen.dart' as _i14;
import 'package:nerobot/screens/profile/all/profile_subscription_screen.dart'
    as _i15;
import 'package:nerobot/screens/profile/all/profile_terms_screen.dart' as _i16;
import 'package:nerobot/screens/profile/all/profile_user_data_screen.dart'
    as _i17;
import 'package:nerobot/screens/profile/profile_screen.dart' as _i13;
import 'package:nerobot/screens/task/chats/chats_screen.dart' as _i2;
import 'package:nerobot/screens/task/create/new_task_create_screen.dart' as _i4;
import 'package:nerobot/screens/task/customers/task_response_screen.dart'
    as _i23;
import 'package:nerobot/screens/task/details/customer/task_customer_profile_screen.dart'
    as _i18;
import 'package:nerobot/screens/task/details/customer/task_detail_customer.dart'
    as _i19;
import 'package:nerobot/screens/task/details/executor/task_detail_executor.dart'
    as _i20;
import 'package:nerobot/screens/task/details/task_detail_screen.dart' as _i21;
import 'package:nerobot/screens/task/executors/task_executors_screen.dart'
    as _i22;
import 'package:nerobot/screens/task/task_screen.dart' as _i24;
import 'package:nerobot/screens/vacancy/vacansy_detail_screen.dart' as _i25;
import 'package:nerobot/screens/vacancy/vacansy_screen.dart' as _i26;
import 'package:nerobot/screens/welcome/welcome_screen.dart' as _i27;

/// generated route for
/// [_i1.AuthScreen]
class AuthRoute extends _i28.PageRouteInfo<AuthRouteArgs> {
  AuthRoute({
    _i29.Key? key,
    required String role,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         AuthRoute.name,
         args: AuthRouteArgs(key: key, role: role),
         initialChildren: children,
       );

  static const String name = 'AuthRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AuthRouteArgs>();
      return _i1.AuthScreen(key: args.key, role: args.role);
    },
  );
}

class AuthRouteArgs {
  const AuthRouteArgs({this.key, required this.role});

  final _i29.Key? key;

  final String role;

  @override
  String toString() {
    return 'AuthRouteArgs{key: $key, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AuthRouteArgs) return false;
    return key == other.key && role == other.role;
  }

  @override
  int get hashCode => key.hashCode ^ role.hashCode;
}

/// generated route for
/// [_i2.ChatsScreen]
class ChatsRoute extends _i28.PageRouteInfo<ChatsRouteArgs> {
  ChatsRoute({
    _i29.Key? key,
    required String chatsId,
    required String taskId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         ChatsRoute.name,
         args: ChatsRouteArgs(key: key, chatsId: chatsId, taskId: taskId),
         initialChildren: children,
       );

  static const String name = 'ChatsRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ChatsRouteArgs>();
      return _i2.ChatsScreen(
        key: args.key,
        chatsId: args.chatsId,
        taskId: args.taskId,
      );
    },
  );
}

class ChatsRouteArgs {
  const ChatsRouteArgs({this.key, required this.chatsId, required this.taskId});

  final _i29.Key? key;

  final String chatsId;

  final String taskId;

  @override
  String toString() {
    return 'ChatsRouteArgs{key: $key, chatsId: $chatsId, taskId: $taskId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatsRouteArgs) return false;
    return key == other.key &&
        chatsId == other.chatsId &&
        taskId == other.taskId;
  }

  @override
  int get hashCode => key.hashCode ^ chatsId.hashCode ^ taskId.hashCode;
}

/// generated route for
/// [_i3.ConfirmScreen]
class ConfirmRoute extends _i28.PageRouteInfo<ConfirmRouteArgs> {
  ConfirmRoute({
    _i29.Key? key,
    required String verificationId,
    required String role,
    required String phoneNumber,
    int? resendToken,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         ConfirmRoute.name,
         args: ConfirmRouteArgs(
           key: key,
           verificationId: verificationId,
           role: role,
           phoneNumber: phoneNumber,
           resendToken: resendToken,
         ),
         initialChildren: children,
       );

  static const String name = 'ConfirmRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ConfirmRouteArgs>();
      return _i3.ConfirmScreen(
        key: args.key,
        verificationId: args.verificationId,
        role: args.role,
        phoneNumber: args.phoneNumber,
        resendToken: args.resendToken,
      );
    },
  );
}

class ConfirmRouteArgs {
  const ConfirmRouteArgs({
    this.key,
    required this.verificationId,
    required this.role,
    required this.phoneNumber,
    this.resendToken,
  });

  final _i29.Key? key;

  final String verificationId;

  final String role;

  final String phoneNumber;

  final int? resendToken;

  @override
  String toString() {
    return 'ConfirmRouteArgs{key: $key, verificationId: $verificationId, role: $role, phoneNumber: $phoneNumber, resendToken: $resendToken}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ConfirmRouteArgs) return false;
    return key == other.key &&
        verificationId == other.verificationId &&
        role == other.role &&
        phoneNumber == other.phoneNumber &&
        resendToken == other.resendToken;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      verificationId.hashCode ^
      role.hashCode ^
      phoneNumber.hashCode ^
      resendToken.hashCode;
}

/// generated route for
/// [_i4.NewTaskCreateScreen]
class NewTaskCreateRoute extends _i28.PageRouteInfo<void> {
  const NewTaskCreateRoute({List<_i28.PageRouteInfo>? children})
    : super(NewTaskCreateRoute.name, initialChildren: children);

  static const String name = 'NewTaskCreateRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i4.NewTaskCreateScreen();
    },
  );
}

/// generated route for
/// [_i5.OnboardingScreen]
class OnboardingRoute extends _i28.PageRouteInfo<OnboardingRouteArgs> {
  OnboardingRoute({
    _i29.Key? key,
    required String role,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         OnboardingRoute.name,
         args: OnboardingRouteArgs(key: key, role: role),
         initialChildren: children,
       );

  static const String name = 'OnboardingRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<OnboardingRouteArgs>();
      return _i5.OnboardingScreen(key: args.key, role: args.role);
    },
  );
}

class OnboardingRouteArgs {
  const OnboardingRouteArgs({this.key, required this.role});

  final _i29.Key? key;

  final String role;

  @override
  String toString() {
    return 'OnboardingRouteArgs{key: $key, role: $role}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! OnboardingRouteArgs) return false;
    return key == other.key && role == other.role;
  }

  @override
  int get hashCode => key.hashCode ^ role.hashCode;
}

/// generated route for
/// [_i6.ProfileAppScreen]
class ProfileAppRoute extends _i28.PageRouteInfo<void> {
  const ProfileAppRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileAppRoute.name, initialChildren: children);

  static const String name = 'ProfileAppRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i6.ProfileAppScreen();
    },
  );
}

/// generated route for
/// [_i7.ProfileEditScreen]
class ProfileEditRoute extends _i28.PageRouteInfo<void> {
  const ProfileEditRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileEditRoute.name, initialChildren: children);

  static const String name = 'ProfileEditRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i7.ProfileEditScreen();
    },
  );
}

/// generated route for
/// [_i8.ProfileFeedbackScreen]
class ProfileFeedbackRoute extends _i28.PageRouteInfo<void> {
  const ProfileFeedbackRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileFeedbackRoute.name, initialChildren: children);

  static const String name = 'ProfileFeedbackRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i8.ProfileFeedbackScreen();
    },
  );
}

/// generated route for
/// [_i9.ProfileHelpScreen]
class ProfileHelpRoute extends _i28.PageRouteInfo<void> {
  const ProfileHelpRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileHelpRoute.name, initialChildren: children);

  static const String name = 'ProfileHelpRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i9.ProfileHelpScreen();
    },
  );
}

/// generated route for
/// [_i10.ProfileHistoryPriceScreen]
class ProfileHistoryPriceRoute extends _i28.PageRouteInfo<void> {
  const ProfileHistoryPriceRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileHistoryPriceRoute.name, initialChildren: children);

  static const String name = 'ProfileHistoryPriceRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i10.ProfileHistoryPriceScreen();
    },
  );
}

/// generated route for
/// [_i11.ProfileNoteScreen]
class ProfileNoteRoute extends _i28.PageRouteInfo<void> {
  const ProfileNoteRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileNoteRoute.name, initialChildren: children);

  static const String name = 'ProfileNoteRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i11.ProfileNoteScreen();
    },
  );
}

/// generated route for
/// [_i12.ProfilePrivacyScreen]
class ProfilePrivacyRoute extends _i28.PageRouteInfo<void> {
  const ProfilePrivacyRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfilePrivacyRoute.name, initialChildren: children);

  static const String name = 'ProfilePrivacyRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i12.ProfilePrivacyScreen();
    },
  );
}

/// generated route for
/// [_i13.ProfileScreen]
class ProfileRoute extends _i28.PageRouteInfo<void> {
  const ProfileRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i13.ProfileScreen();
    },
  );
}

/// generated route for
/// [_i14.ProfileStarsScreen]
class ProfileStarsRoute extends _i28.PageRouteInfo<void> {
  const ProfileStarsRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileStarsRoute.name, initialChildren: children);

  static const String name = 'ProfileStarsRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i14.ProfileStarsScreen();
    },
  );
}

/// generated route for
/// [_i15.ProfileSubscriptionScreen]
class ProfileSubscriptionRoute extends _i28.PageRouteInfo<void> {
  const ProfileSubscriptionRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileSubscriptionRoute.name, initialChildren: children);

  static const String name = 'ProfileSubscriptionRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i15.ProfileSubscriptionScreen();
    },
  );
}

/// generated route for
/// [_i16.ProfileTermsScreen]
class ProfileTermsRoute extends _i28.PageRouteInfo<void> {
  const ProfileTermsRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileTermsRoute.name, initialChildren: children);

  static const String name = 'ProfileTermsRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i16.ProfileTermsScreen();
    },
  );
}

/// generated route for
/// [_i17.ProfileUserDataScreen]
class ProfileUserDataRoute extends _i28.PageRouteInfo<void> {
  const ProfileUserDataRoute({List<_i28.PageRouteInfo>? children})
    : super(ProfileUserDataRoute.name, initialChildren: children);

  static const String name = 'ProfileUserDataRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i17.ProfileUserDataScreen();
    },
  );
}

/// generated route for
/// [_i18.TaskCustomerProfileScreen]
class TaskCustomerProfileRoute
    extends _i28.PageRouteInfo<TaskCustomerProfileRouteArgs> {
  TaskCustomerProfileRoute({
    _i29.Key? key,
    required String profileCustomerId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskCustomerProfileRoute.name,
         args: TaskCustomerProfileRouteArgs(
           key: key,
           profileCustomerId: profileCustomerId,
         ),
         rawPathParams: {'profileCustomerId': profileCustomerId},
         initialChildren: children,
       );

  static const String name = 'TaskCustomerProfileRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TaskCustomerProfileRouteArgs>(
        orElse:
            () => TaskCustomerProfileRouteArgs(
              profileCustomerId: pathParams.getString('profileCustomerId'),
            ),
      );
      return _i18.TaskCustomerProfileScreen(
        key: args.key,
        profileCustomerId: args.profileCustomerId,
      );
    },
  );
}

class TaskCustomerProfileRouteArgs {
  const TaskCustomerProfileRouteArgs({
    this.key,
    required this.profileCustomerId,
  });

  final _i29.Key? key;

  final String profileCustomerId;

  @override
  String toString() {
    return 'TaskCustomerProfileRouteArgs{key: $key, profileCustomerId: $profileCustomerId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskCustomerProfileRouteArgs) return false;
    return key == other.key && profileCustomerId == other.profileCustomerId;
  }

  @override
  int get hashCode => key.hashCode ^ profileCustomerId.hashCode;
}

/// generated route for
/// [_i19.TaskDetailCustomerScreen]
class TaskDetailCustomerRoute
    extends _i28.PageRouteInfo<TaskDetailCustomerRouteArgs> {
  TaskDetailCustomerRoute({
    _i29.Key? key,
    required String taskId,
    String? respondent,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskDetailCustomerRoute.name,
         args: TaskDetailCustomerRouteArgs(
           key: key,
           taskId: taskId,
           respondent: respondent,
         ),
         initialChildren: children,
       );

  static const String name = 'TaskDetailCustomerRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailCustomerRouteArgs>();
      return _i19.TaskDetailCustomerScreen(
        key: args.key,
        taskId: args.taskId,
        respondent: args.respondent,
      );
    },
  );
}

class TaskDetailCustomerRouteArgs {
  const TaskDetailCustomerRouteArgs({
    this.key,
    required this.taskId,
    this.respondent,
  });

  final _i29.Key? key;

  final String taskId;

  final String? respondent;

  @override
  String toString() {
    return 'TaskDetailCustomerRouteArgs{key: $key, taskId: $taskId, respondent: $respondent}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDetailCustomerRouteArgs) return false;
    return key == other.key &&
        taskId == other.taskId &&
        respondent == other.respondent;
  }

  @override
  int get hashCode => key.hashCode ^ taskId.hashCode ^ respondent.hashCode;
}

/// generated route for
/// [_i20.TaskDetailExecutorScreen]
class TaskDetailExecutorRoute
    extends _i28.PageRouteInfo<TaskDetailExecutorRouteArgs> {
  TaskDetailExecutorRoute({
    _i29.Key? key,
    required String taskId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskDetailExecutorRoute.name,
         args: TaskDetailExecutorRouteArgs(key: key, taskId: taskId),
         initialChildren: children,
       );

  static const String name = 'TaskDetailExecutorRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskDetailExecutorRouteArgs>();
      return _i20.TaskDetailExecutorScreen(key: args.key, taskId: args.taskId);
    },
  );
}

class TaskDetailExecutorRouteArgs {
  const TaskDetailExecutorRouteArgs({this.key, required this.taskId});

  final _i29.Key? key;

  final String taskId;

  @override
  String toString() {
    return 'TaskDetailExecutorRouteArgs{key: $key, taskId: $taskId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDetailExecutorRouteArgs) return false;
    return key == other.key && taskId == other.taskId;
  }

  @override
  int get hashCode => key.hashCode ^ taskId.hashCode;
}

/// generated route for
/// [_i21.TaskDetailScreen]
class TaskDetailRoute extends _i28.PageRouteInfo<TaskDetailRouteArgs> {
  TaskDetailRoute({
    _i29.Key? key,
    required String taskId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskDetailRoute.name,
         args: TaskDetailRouteArgs(key: key, taskId: taskId),
         rawPathParams: {'taskId': taskId},
         initialChildren: children,
       );

  static const String name = 'TaskDetailRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<TaskDetailRouteArgs>(
        orElse:
            () => TaskDetailRouteArgs(taskId: pathParams.getString('taskId')),
      );
      return _i21.TaskDetailScreen(key: args.key, taskId: args.taskId);
    },
  );
}

class TaskDetailRouteArgs {
  const TaskDetailRouteArgs({this.key, required this.taskId});

  final _i29.Key? key;

  final String taskId;

  @override
  String toString() {
    return 'TaskDetailRouteArgs{key: $key, taskId: $taskId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskDetailRouteArgs) return false;
    return key == other.key && taskId == other.taskId;
  }

  @override
  int get hashCode => key.hashCode ^ taskId.hashCode;
}

/// generated route for
/// [_i22.TaskExecutorsScreen]
class TaskExecutorsRoute extends _i28.PageRouteInfo<TaskExecutorsRouteArgs> {
  TaskExecutorsRoute({
    _i29.Key? key,
    required String taskId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskExecutorsRoute.name,
         args: TaskExecutorsRouteArgs(key: key, taskId: taskId),
         initialChildren: children,
       );

  static const String name = 'TaskExecutorsRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskExecutorsRouteArgs>();
      return _i22.TaskExecutorsScreen(key: args.key, taskId: args.taskId);
    },
  );
}

class TaskExecutorsRouteArgs {
  const TaskExecutorsRouteArgs({this.key, required this.taskId});

  final _i29.Key? key;

  final String taskId;

  @override
  String toString() {
    return 'TaskExecutorsRouteArgs{key: $key, taskId: $taskId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskExecutorsRouteArgs) return false;
    return key == other.key && taskId == other.taskId;
  }

  @override
  int get hashCode => key.hashCode ^ taskId.hashCode;
}

/// generated route for
/// [_i23.TaskResponseScreen]
class TaskResponseRoute extends _i28.PageRouteInfo<TaskResponseRouteArgs> {
  TaskResponseRoute({
    _i29.Key? key,
    required String taskId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         TaskResponseRoute.name,
         args: TaskResponseRouteArgs(key: key, taskId: taskId),
         initialChildren: children,
       );

  static const String name = 'TaskResponseRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<TaskResponseRouteArgs>();
      return _i23.TaskResponseScreen(key: args.key, taskId: args.taskId);
    },
  );
}

class TaskResponseRouteArgs {
  const TaskResponseRouteArgs({this.key, required this.taskId});

  final _i29.Key? key;

  final String taskId;

  @override
  String toString() {
    return 'TaskResponseRouteArgs{key: $key, taskId: $taskId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskResponseRouteArgs) return false;
    return key == other.key && taskId == other.taskId;
  }

  @override
  int get hashCode => key.hashCode ^ taskId.hashCode;
}

/// generated route for
/// [_i24.TaskScreen]
class TaskRoute extends _i28.PageRouteInfo<void> {
  const TaskRoute({List<_i28.PageRouteInfo>? children})
    : super(TaskRoute.name, initialChildren: children);

  static const String name = 'TaskRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i24.TaskScreen();
    },
  );
}

/// generated route for
/// [_i25.VacansyDetailScreen]
class VacansyDetailRoute extends _i28.PageRouteInfo<VacansyDetailRouteArgs> {
  VacansyDetailRoute({
    _i29.Key? key,
    required String vacansyId,
    List<_i28.PageRouteInfo>? children,
  }) : super(
         VacansyDetailRoute.name,
         args: VacansyDetailRouteArgs(key: key, vacansyId: vacansyId),
         initialChildren: children,
       );

  static const String name = 'VacansyDetailRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<VacansyDetailRouteArgs>();
      return _i25.VacansyDetailScreen(key: args.key, vacansyId: args.vacansyId);
    },
  );
}

class VacansyDetailRouteArgs {
  const VacansyDetailRouteArgs({this.key, required this.vacansyId});

  final _i29.Key? key;

  final String vacansyId;

  @override
  String toString() {
    return 'VacansyDetailRouteArgs{key: $key, vacansyId: $vacansyId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! VacansyDetailRouteArgs) return false;
    return key == other.key && vacansyId == other.vacansyId;
  }

  @override
  int get hashCode => key.hashCode ^ vacansyId.hashCode;
}

/// generated route for
/// [_i26.VacansyScreen]
class VacansyRoute extends _i28.PageRouteInfo<void> {
  const VacansyRoute({List<_i28.PageRouteInfo>? children})
    : super(VacansyRoute.name, initialChildren: children);

  static const String name = 'VacansyRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i26.VacansyScreen();
    },
  );
}

/// generated route for
/// [_i27.WelcomeScreen]
class WelcomeRoute extends _i28.PageRouteInfo<void> {
  const WelcomeRoute({List<_i28.PageRouteInfo>? children})
    : super(WelcomeRoute.name, initialChildren: children);

  static const String name = 'WelcomeRoute';

  static _i28.PageInfo page = _i28.PageInfo(
    name,
    builder: (data) {
      return const _i27.WelcomeScreen();
    },
  );
}
