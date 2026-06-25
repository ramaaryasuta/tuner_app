import '../../services/beat_audio_service.dart';
import '../entity/beat_settings.dart';

class StartBeatUsecase {
  final BeatAudioService _service;
  const StartBeatUsecase(this._service);

  Future<void> call(BeatSettings settings) => _service.start(settings);
}
