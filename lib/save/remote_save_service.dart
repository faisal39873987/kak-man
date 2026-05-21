import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../backend/supabase_backend.dart';
import 'game_save_data.dart';

class RemoteSaveService {
  RemoteSaveService({SupabaseClient? client}) : _client = client;

  static const String tableName = 'nerve_runner_profiles';

  final SupabaseClient? _client;

  SupabaseClient? get _activeClient => _client ?? SupabaseBackend.client;

  Future<GameSaveData?> load() async {
    final client = _activeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return null;
    }

    try {
      final row = await client
          .from(tableName)
          .select('save_data')
          .eq('player_id', user.id)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      final saveData = row['save_data'];
      if (saveData is! Map) {
        return null;
      }
      return GameSaveData.fromJson(saveData.cast<String, Object?>());
    } catch (error, stackTrace) {
      _reportSyncError(error, stackTrace, 'loading remote save');
      return null;
    }
  }

  Future<void> save(GameSaveData data) async {
    final client = _activeClient;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return;
    }

    try {
      await client.from(tableName).upsert(<String, Object>{
        'player_id': user.id,
        'save_data': data.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error, stackTrace) {
      _reportSyncError(error, stackTrace, 'saving remote progress');
    }
  }

  void _reportSyncError(Object error, StackTrace stackTrace, String context) {
    if (!kDebugMode) {
      return;
    }
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'one_shot_nerve_runner.save',
        context: ErrorDescription(context),
      ),
    );
  }
}
