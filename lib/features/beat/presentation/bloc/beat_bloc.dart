import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/beat_settings.dart';
import '../../domain/repository/beat_setting_repository.dart';
import '../../domain/usecase/start_beat_usecase.dart';
import '../../domain/usecase/stop_beat_usecase.dart';
import '../../domain/usecase/update_beat_settings_usecase.dart';
import '../../services/beat_audio_service.dart';
import 'beat_event.dart';
import 'beat_state.dart';

/// Jeda maksimal antar ketukan tap tempo (ms).
/// Jika lebih lama dari ini, sesi tap dianggap reset.
const _tapTimeoutMs = 2500;

/// Minimal ketukan untuk menghitung BPM dari tap tempo.
const _minTapsForBpm = 4;

/// Maksimal history tap yang disimpan (lebih stabil dengan rata-rata lebih banyak)
const _maxTapHistory = 8;

class BeatBloc extends Bloc<BeatEvent, BeatState> {
  final BeatSettingsRepository _repository;
  final StartBeatUsecase _startBeat;
  final StopBeatUsecase _stopBeat;
  final UpdateBeatSettingsUsecase _updateSettings;
  final BeatAudioService _audioService;

  StreamSubscription<BeatTickState>? _tickSubscription;

  BeatBloc({
    required BeatSettingsRepository repository,
    required StartBeatUsecase startBeat,
    required StopBeatUsecase stopBeat,
    required UpdateBeatSettingsUsecase updateSettings,
    required BeatAudioService audioService,
  }) : _repository = repository,
       _startBeat = startBeat,
       _stopBeat = stopBeat,
       _updateSettings = updateSettings,
       _audioService = audioService,
       super(const BeatState()) {
    on<BeatInitialized>(_onInitialized);
    on<BeatPlayToggled>(_onPlayToggled);
    on<BeatBpmChanged>(_onBpmChanged);
    on<BeatTapTempoTapped>(_onTapTempoTapped);
    on<BeatTimeSignatureChanged>(_onTimeSignatureChanged);
    on<BeatSoundTypeChanged>(_onSoundTypeChanged);
    on<BeatVolumeChanged>(_onVolumeChanged);
    on<BeatAccentToggled>(_onAccentToggled);
    on<BeatTicked>(_onTicked);
  }

  // ─────────────────────────────────────────────
  // Handlers
  // ─────────────────────────────────────────────

  Future<void> _onInitialized(
    BeatInitialized event,
    Emitter<BeatState> emit,
  ) async {
    emit(state.copyWith(status: BeatStatus.loading));
    try {
      await _audioService.init();
      final saved = await _repository.loadSettings();
      emit(
        state.copyWith(
          status: BeatStatus.stopped,
          settings: saved,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: BeatStatus.error,
          errorMessage: 'Gagal menginisialisasi beat: $e',
        ),
      );
    }
  }

  Future<void> _onPlayToggled(
    BeatPlayToggled event,
    Emitter<BeatState> emit,
  ) async {
    if (state.isPlaying) {
      await _stopBeat();
      _tickSubscription?.cancel();
      emit(state.copyWith(status: BeatStatus.stopped, clearActiveBeat: true));
    } else {
      try {
        // Subscribe ke tick stream sebelum mulai
        _tickSubscription?.cancel();
        _tickSubscription = _audioService.tickStream.listen((tick) {
          add(
            BeatTicked(
              beatIndex: tick.beatIndex,
              totalBeats: tick.totalBeats,
              isAccent: tick.isAccent,
            ),
          );
        });

        await _startBeat(state.settings);
        emit(state.copyWith(status: BeatStatus.playing, clearError: true));
      } catch (e) {
        emit(
          state.copyWith(
            status: BeatStatus.error,
            errorMessage: 'Gagal memulai beat: $e',
          ),
        );
      }
    }
  }

  Future<void> _onBpmChanged(
    BeatBpmChanged event,
    Emitter<BeatState> emit,
  ) async {
    final clamped = event.bpm.clamp(BeatSettings.minBpm, BeatSettings.maxBpm);
    final updated = state.settings.copyWith(bpm: clamped);

    emit(
      state.copyWith(
        settings: updated,
        clearTapTempo: true, // reset tap tempo preview
      ),
    );

    await _updateSettings(updated);
  }

  Future<void> _onTapTempoTapped(
    BeatTapTempoTapped event,
    Emitter<BeatState> emit,
  ) async {
    final now = DateTime.now();
    final history = List<DateTime>.from(state.tapHistory);

    // Reset jika jeda terlalu lama
    if (history.isNotEmpty) {
      final gap = now.difference(history.last).inMilliseconds;
      if (gap > _tapTimeoutMs) history.clear();
    }

    history.add(now);

    // Batasi panjang history
    if (history.length > _maxTapHistory) {
      history.removeAt(0);
    }

    // Hitung BPM dari rata-rata interval antar ketukan
    if (history.length >= _minTapsForBpm) {
      final intervals = <int>[];
      for (int i = 1; i < history.length; i++) {
        intervals.add(history[i].difference(history[i - 1]).inMilliseconds);
      }
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final tappedBpm = (60000 / avgInterval).round().clamp(
        BeatSettings.minBpm,
        BeatSettings.maxBpm,
      );

      // Commit langsung ke settings
      final updated = state.settings.copyWith(bpm: tappedBpm);
      emit(
        state.copyWith(
          settings: updated,
          tapHistory: history,
          tapTempoBpm: tappedBpm,
        ),
      );
      await _updateSettings(updated);
    } else {
      // Belum cukup tap, hanya update history
      emit(state.copyWith(tapHistory: history));
    }
  }

  Future<void> _onTimeSignatureChanged(
    BeatTimeSignatureChanged event,
    Emitter<BeatState> emit,
  ) async {
    final updated = state.settings.copyWith(timeSignature: event.timeSignature);
    emit(state.copyWith(settings: updated));
    await _updateSettings(updated);
  }

  Future<void> _onSoundTypeChanged(
    BeatSoundTypeChanged event,
    Emitter<BeatState> emit,
  ) async {
    final updated = state.settings.copyWith(soundType: event.soundType);
    emit(state.copyWith(settings: updated));
    await _updateSettings(updated);
  }

  Future<void> _onVolumeChanged(
    BeatVolumeChanged event,
    Emitter<BeatState> emit,
  ) async {
    final clamped = event.volume.clamp(0.0, 1.0);
    final updated = state.settings.copyWith(volume: clamped);
    emit(state.copyWith(settings: updated));
    await _updateSettings(updated);
  }

  Future<void> _onAccentToggled(
    BeatAccentToggled event,
    Emitter<BeatState> emit,
  ) async {
    final updated = state.settings.copyWith(
      accentFirstBeat: !state.settings.accentFirstBeat,
    );
    emit(state.copyWith(settings: updated));
    await _updateSettings(updated);
  }

  /// Dipanggil setiap tick dari audio service — update UI highlight beat
  void _onTicked(BeatTicked event, Emitter<BeatState> emit) {
    emit(state.copyWith(activeBeatIndex: event.beatIndex));
  }

  @override
  Future<void> close() async {
    _tickSubscription?.cancel();
    await _stopBeat();
    return super.close();
  }
}
