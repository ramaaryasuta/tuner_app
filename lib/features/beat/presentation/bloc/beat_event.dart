import 'package:equatable/equatable.dart';

import '../../domain/entity/beat_settings.dart';

sealed class BeatEvent extends Equatable {
  const BeatEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi: load saved settings dari storage
final class BeatInitialized extends BeatEvent {
  const BeatInitialized();
}

/// Toggle play/stop
final class BeatPlayToggled extends BeatEvent {
  const BeatPlayToggled();
}

/// BPM diubah (dari slider atau tap tempo)
final class BeatBpmChanged extends BeatEvent {
  final int bpm;
  const BeatBpmChanged(this.bpm);

  @override
  List<Object?> get props => [bpm];
}

/// Tap tempo: user mengetuk layar untuk detect BPM
final class BeatTapTempoTapped extends BeatEvent {
  const BeatTapTempoTapped();
}

/// Time signature diubah
final class BeatTimeSignatureChanged extends BeatEvent {
  final TimeSignatureNumerator timeSignature;
  const BeatTimeSignatureChanged(this.timeSignature);

  @override
  List<Object?> get props => [timeSignature];
}

/// Jenis suara diubah
final class BeatSoundTypeChanged extends BeatEvent {
  final BeatSoundType soundType;
  const BeatSoundTypeChanged(this.soundType);

  @override
  List<Object?> get props => [soundType];
}

/// Volume diubah
final class BeatVolumeChanged extends BeatEvent {
  final double volume;
  const BeatVolumeChanged(this.volume);

  @override
  List<Object?> get props => [volume];
}

/// Accent first beat toggle
final class BeatAccentToggled extends BeatEvent {
  const BeatAccentToggled();
}

/// Tick dari audio service (untuk animasi UI)
final class BeatTicked extends BeatEvent {
  final int beatIndex;
  final int totalBeats;
  final bool isAccent;

  const BeatTicked({
    required this.beatIndex,
    required this.totalBeats,
    required this.isAccent,
  });

  @override
  List<Object?> get props => [beatIndex, totalBeats, isAccent];
}
