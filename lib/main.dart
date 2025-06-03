import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nerobot/constants/app_colors.dart';
import 'package:nerobot/firebase_options.dart';
import 'package:nerobot/router/app_router.dart';
import 'package:nerobot/themes/text_themes.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  getIt.registerSingleton<AppRouter>(AppRouter());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('ru_RU', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appRouter = getIt<AppRouter>();

    return MaterialApp.router(
      routerConfig: appRouter.config(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(AppColors.violet.value, {
            50: AppColors.violet.withOpacity(0.1),
            100: AppColors.violet.withOpacity(0.2),
            200: AppColors.violet.withOpacity(0.3),
            300: AppColors.violet.withOpacity(0.4),
            400: AppColors.violet.withOpacity(0.5),
            500: AppColors.violet,
            600: AppColors.violet.withOpacity(0.7),
            700: AppColors.violet.withOpacity(0.8),
            800: AppColors.violet.withOpacity(0.9),
            900: AppColors.violet,
          }),
        ),
        primarySwatch: Colors.blue,
        textTheme: buildTextTheme(),
      ),
    );
  }
}
