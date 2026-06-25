import 'package:equatable/equatable.dart';

import '../../domain/entity/beat_settings.dart';

enum BeatStatus { initial, loading, playing, stopped, error }

class BeatState extends Equatable {
  final BeatStatus status;
  final BeatSettings settings;

  /// Beat yang sedang aktif dalam bar saat ini (0-based), null kalau stopped
  final int? activeBeatIndex;

  /// Untuk tap tempo: timestamps ketukan terakhir
  final List<DateTime> tapHistory;

  /// BPM estimasi dari tap tempo (ditampilkan sebelum di-commit)
  final int? tapTempoBpm;

  final String? errorMessage;

  const BeatState({
    this.status = BeatStatus.initial,
    this.settings = const BeatSettings(),
    this.activeBeatIndex,
    this.tapHistory = const [],
    this.tapTempoBpm,
    this.errorMessage,
  });

  bool get isPlaying => status == BeatStatus.playing;

  /// BPM yang ditampilkan: pakai tapTempoBpm kalau sedang tap, otherwise settings.bpm
  int get displayBpm => tapTempoBpm ?? settings.bpm;

  BeatState copyWith({
    BeatStatus? status,
    BeatSettings? settings,
    int? activeBeatIndex,
    bool clearActiveBeat = false,
    List<DateTime>? tapHistory,
    int? tapTempoBpm,
    bool clearTapTempo = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BeatState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      activeBeatIndex: clearActiveBeat
          ? null
          : (activeBeatIndex ?? this.activeBeatIndex),
      tapHistory: tapHistory ?? this.tapHistory,
      tapTempoBpm: clearTapTempo ? null : (tapTempoBpm ?? this.tapTempoBpm),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    activeBeatIndex,
    tapHistory,
    tapTempoBpm,
    errorMessage,
  ];
}
