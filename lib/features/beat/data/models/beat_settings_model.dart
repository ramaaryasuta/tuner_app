import '../../domain/entity/beat_settings.dart';

class BeatSettingsModel extends BeatSettings {
  const BeatSettingsModel({
    super.bpm,
    super.timeSignature,
    super.soundType,
    super.accentFirstBeat,
    super.volume,
  });

  factory BeatSettingsModel.fromJson(Map<String, dynamic> json) {
    return BeatSettingsModel(
      bpm: json['bpm'] as int? ?? 120,
      timeSignature: TimeSignatureNumerator.values.firstWhere(
        (e) => e.name == json['time_signature'],
        orElse: () => TimeSignatureNumerator.four,
      ),
      soundType: BeatSoundType.values.firstWhere(
        (e) => e.name == json['sound_type'],
        orElse: () => BeatSoundType.click,
      ),
      accentFirstBeat: json['accent_first_beat'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bpm': bpm,
      'time_signature': timeSignature.name,
      'sound_type': soundType.name,
      'accent_first_beat': accentFirstBeat,
      'volume': volume,
    };
  }

  factory BeatSettingsModel.fromEntity(BeatSettings entity) {
    return BeatSettingsModel(
      bpm: entity.bpm,
      timeSignature: entity.timeSignature,
      soundType: entity.soundType,
      accentFirstBeat: entity.accentFirstBeat,
      volume: entity.volume,
    );
  }
}
