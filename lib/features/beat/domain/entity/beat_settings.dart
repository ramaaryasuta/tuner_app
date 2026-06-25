import 'package:equatable/equatable.dart';

enum TimeSignatureNumerator { two, three, four, five, six, seven }

extension TimeSignatureNumeratorX on TimeSignatureNumerator {
  int get value => switch (this) {
    TimeSignatureNumerator.two => 2,
    TimeSignatureNumerator.three => 3,
    TimeSignatureNumerator.four => 4,
    TimeSignatureNumerator.five => 5,
    TimeSignatureNumerator.six => 6,
    TimeSignatureNumerator.seven => 7,
  };
}

enum BeatSoundType { click, woodblock, cowbell, rimshot }

class BeatSettings extends Equatable {
  final int bpm;
  final TimeSignatureNumerator timeSignature;
  final BeatSoundType soundType;
  final bool accentFirstBeat; // downbeat lebih keras
  final double volume; // 0.0 - 1.0

  const BeatSettings({
    this.bpm = 120,
    this.timeSignature = TimeSignatureNumerator.four,
    this.soundType = BeatSoundType.click,
    this.accentFirstBeat = true,
    this.volume = 0.8,
  });

  static const int minBpm = 20;
  static const int maxBpm = 300;

  BeatSettings copyWith({
    int? bpm,
    TimeSignatureNumerator? timeSignature,
    BeatSoundType? soundType,
    bool? accentFirstBeat,
    double? volume,
  }) {
    return BeatSettings(
      bpm: bpm ?? this.bpm,
      timeSignature: timeSignature ?? this.timeSignature,
      soundType: soundType ?? this.soundType,
      accentFirstBeat: accentFirstBeat ?? this.accentFirstBeat,
      volume: volume ?? this.volume,
    );
  }

  /// Interval antar beat dalam milidetik
  double get intervalMs => 60000.0 / bpm;

  /// Interval dalam detik (untuk SoLoud scheduling)
  double get intervalSeconds => 60.0 / bpm;

  @override
  List<Object?> get props => [
    bpm,
    timeSignature,
    soundType,
    accentFirstBeat,
    volume,
  ];
}
