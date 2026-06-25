import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../domain/entity/beat_settings.dart';
import '../../domain/repository/beat_setting_repository.dart';
import '../models/beat_settings_model.dart';

class BeatSettingsRepositoryImpl implements BeatSettingsRepository {
  static const _key = 'beat_settings';

  final SharedPreferences _prefs;

  const BeatSettingsRepositoryImpl(this._prefs);

  @override
  Future<BeatSettings> loadSettings() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return const BeatSettings();

    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return BeatSettingsModel.fromJson(json);
    } catch (_) {
      return const BeatSettings();
    }
  }

  @override
  Future<void> saveSettings(BeatSettings settings) async {
    final model = BeatSettingsModel.fromEntity(settings);
    await _prefs.setString(_key, jsonEncode(model.toJson()));
  }

  @override
  Future<void> resetSettings() async {
    await _prefs.remove(_key);
  }
}
