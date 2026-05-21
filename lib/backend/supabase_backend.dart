import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';

class SupabaseBackend {
  const SupabaseBackend._();

  static bool _initialized = false;
  static bool _available = false;

  static bool get available => _available;

  static SupabaseClient? get client {
    if (!_available) {
      return null;
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!SupabaseConfig.configured) {
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.publishableKey,
      );
      _available = true;
      await _ensureSession();
    } catch (error, stackTrace) {
      _available = false;
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'one_shot_nerve_runner.backend',
            context: ErrorDescription('initializing Supabase'),
          ),
        );
      }
    }
  }

  static Future<void> _ensureSession() async {
    final supabase = client;
    if (supabase == null || supabase.auth.currentSession != null) {
      return;
    }

    try {
      await supabase.auth.signInAnonymously();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'one_shot_nerve_runner.backend',
            context: ErrorDescription('starting anonymous Supabase session'),
          ),
        );
      }
    }
  }
}
