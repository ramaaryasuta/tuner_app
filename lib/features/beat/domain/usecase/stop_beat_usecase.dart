import '../../services/beat_audio_service.dart';

class StopBeatUsecase {
  final BeatAudioService _service;
  const StopBeatUsecase(this._service);

  Future<void> call() => _service.stop();
}
