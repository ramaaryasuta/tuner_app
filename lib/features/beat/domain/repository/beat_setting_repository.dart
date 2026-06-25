import '../entity/beat_settings.dart';

abstract class BeatSettingsRepository {
  /// Load pengaturan beat terakhir dari local storage
  Future<BeatSettings> loadSettings();

  /// Simpan pengaturan beat
  Future<void> saveSettings(BeatSettings settings);

  /// Reset ke default
  Future<void> resetSettings();
}
