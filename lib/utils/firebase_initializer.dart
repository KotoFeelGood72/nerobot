import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart'; // проверьте путь: lib/firebase_options.dart

class FirebaseInitializer {
  static Future<void>? _initFuture;
  static bool _initialized = false;

  /// Инициализирует Firebase только если ещё не инициализировано.
  /// Параллельные вызовы в одном isolate будут ждать одного Future.
  static Future<void> initialize() {
    WidgetsFlutterBinding.ensureInitialized();

    if (_initialized) return Future.value();

    _initFuture ??= _doInitialize();
    return _initFuture!;
  }

  static Future<void> _doInitialize() async {
    // Небольшая двойная проверка перед реальной инициализацией.
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      if (kDebugMode) debugPrint('FirebaseInitializer: already initialized (existing apps).');
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      if (kDebugMode) debugPrint('FirebaseInitializer: Firebase initialized successfully.');
    } on FirebaseException catch (e) {
      final msg = e.message ?? e.toString();
      // Тихо игнорируем дубликат — не печатаем весь стек.
      if (e.code == 'duplicate-app' || msg.contains('already exists')) {
        try {
          Firebase.app();
          _initialized = true;
        } catch (_) {
          _initialized = true;
        }
        if (kDebugMode) debugPrint('FirebaseInitializer: duplicate init ignored');
        return;
      }
      // Для прочих ошибок пробрасываем дальше
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      // Очистим _initFuture, чтобы повторные (после ошибки) попытки могли заново инициировать
      _initFuture = null;
    }
  }
}