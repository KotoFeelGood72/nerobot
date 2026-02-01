import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

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
    if (Firebase.apps.isNotEmpty) {
      _initialized = true;
      if (kDebugMode) debugPrint('FirebaseInitializer: already initialized (existing apps).');
      return;
    }

    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: options);
      _initialized = true;
      if (kDebugMode) debugPrint('FirebaseInitializer: Firebase initialized successfully.');
    } on UnsupportedError catch (e) {
      _initialized = true;
      if (kDebugMode) {
        debugPrint('FirebaseInitializer: Firebase not configured for this platform ($e). Skipping.');
      }
      return;
    } on FirebaseException catch (e) {
      final msg = e.message ?? e.toString();
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
      rethrow;
    } catch (e) {
      rethrow;
    } finally {
      _initFuture = null;
    }
  }
}