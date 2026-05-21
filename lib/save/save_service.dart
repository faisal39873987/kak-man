import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_save_data.dart';
import 'remote_save_service.dart';
import 'save_data_ranker.dart';

class SaveService {
  SaveService({RemoteSaveService? remote})
    : _remote = remote ?? RemoteSaveService();

  static const String _saveKey = 'one_shot_nerve_runner.save.v1';

  final RemoteSaveService _remote;

  Future<GameSaveData> load() async {
    final local = await _loadLocal();
    final remote = await _remote.load();
    if (remote == null) {
      return local;
    }
    final richest = SaveDataRanker.richest(local, remote);
    await _saveLocal(richest);
    return richest;
  }

  Future<void> save(GameSaveData data) async {
    await _saveLocal(data);
    await _remote.save(data);
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
