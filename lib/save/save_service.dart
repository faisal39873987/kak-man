import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_save_data.dart';
import 'remote_save_service.dart';
import 'save_data_ranker.dart';
import 'save_sync_status.dart';

class SaveService {
  SaveService({RemoteSaveService? remote})
    : _remote = remote ?? RemoteSaveService();

  static const String _saveKey = 'one_shot_nerve_runner.save.v1';

  final RemoteSaveService _remote;
  SaveSyncStatus _syncStatus = SaveSyncStatus.localOnly;

  SaveSyncStatus get syncStatus => _syncStatus;

  Future<GameSaveData> load() async {
    final local = await _loadLocal();
    _syncStatus = SaveSyncStatus.syncing;
    final remote = await _remote.load();
    if (!remote.canSync) {
      _syncStatus = SaveSyncStatus.localOnly;
      return local;
    }
    if (remote.failed) {
      _syncStatus = SaveSyncStatus.remoteError;
      return local;
    }
    final remoteData = remote.data;
    if (remoteData == null) {
      _syncStatus = await _remote.save(local)
          ? SaveSyncStatus.synced
          : SaveSyncStatus.remoteError;
      return local;
    }
    final richest = SaveDataRanker.richest(local, remoteData);
    await _saveLocal(richest);
    _syncStatus = await _remote.save(richest)
        ? SaveSyncStatus.synced
        : SaveSyncStatus.remoteError;
    return richest;
  }

  Future<void> save(GameSaveData data) async {
    await _saveLocal(data);
    if (!_remote.canSync) {
      _syncStatus = SaveSyncStatus.localOnly;
      return;
    }
    _syncStatus = SaveSyncStatus.syncing;
    _syncStatus = await _remote.save(data)
        ? SaveSyncStatus.synced
        : SaveSyncStatus.remoteError;
  }

  Future<GameSaveData> _loadLocal() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_saveKey);
    if (raw == null || raw.isEmpty) {
      return GameSaveData.fresh();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return GameSaveData.fresh();
      }
      return GameSaveData.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      return GameSaveData.fresh();
    }
  }

  Future<void> _saveLocal(GameSaveData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_saveKey, jsonEncode(data.toJson()));
  }
}
