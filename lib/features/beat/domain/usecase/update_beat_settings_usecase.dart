import '../../services/beat_audio_service.dart';
import '../entity/beat_settings.dart';
import '../repository/beat_setting_repository.dart';

class UpdateBeatSettingsUsecase {
  final BeatSettingsRepository _repository;
  final BeatAudioService _service;

  const UpdateBeatSettingsUsecase(this._repository, this._service);

  Future<void> call(BeatSettings settings) async {
    await _repository.saveSettings(settings);
    if (_service.isPlaying) {
      await _service.updateSettings(settings);
    }
  }
}
