import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:tuner_app/features/tuner/domain/pitch_detector.dart';
import 'package:tuner_app/features/tuner/presentation/bloc/tuner_event.dart';
import 'package:tuner_app/features/tuner/presentation/bloc/tuner_state.dart';

class TunerBloc extends Bloc<TunerEvent, TunerState> {
  final AudioRecorder _recorder = AudioRecorder();

  StreamSubscription? _audioSub;

  final List<double> _freqHistory = [];
  static const int _historySize = 18;

  // Menyimpan hasil terakhir
  TunerDetected? _lastDetected;

  // Berapa frame berturut-turut yang gagal detect
  int _missedFrames = 0;

  // Misalnya 15 frame (~700ms jika update sekitar 50ms/frame)
  static const int _maxMissedFrames = 15;

  TunerBloc() : super(TunerIdle()) {
    on<TunerStarted>(_onStarted);
    on<TunerStopped>(_onStopped);
    on<TunerAudioReceived>(_onAudioReceived);
  }

  Future<void> _onStarted(TunerStarted event, Emitter<TunerState> emit) async {
    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) return;

    emit(TunerListening());

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 44100,
        numChannels: 1,
      ),
    );

    List<double> buffer = [];
    const int windowSize = 4096;
    const int hopSize = 2048; // Proses setiap 2048 sample baru

    _audioSub = stream.listen((data) {
      for (int i = 0; i < data.length - 1; i += 2) {
        int sample = (data[i + 1] << 8) | data[i];
        if (sample > 32767) sample -= 65536;
        buffer.add(sample / 32768.0);
      }

      // Proses setiap kali buffer punya cukup data untuk satu hop
      while (buffer.length >= windowSize) {
        add(TunerAudioReceived(buffer.take(windowSize).toList()));

        // Geser buffer sebesar hopSize, bukan clear total
        buffer.removeRange(0, hopSize);
      }
    });
  }

  void _onAudioReceived(TunerAudioReceived event, Emitter<TunerState> emit) {
    final freq = PitchDetector.detectPitch(event.samples);

    // Tidak ada pitch terdeteksi
    if (freq == null) {
      _missedFrames++;

      // Tetap tampilkan hasil terakhir selama beberapa frame
      if (_missedFrames < _maxMissedFrames && _lastDetected != null) {
        emit(_lastDetected!);
        return;
      }

      _freqHistory.clear();
      _lastDetected = null;
      emit(TunerNoSignal());
      return;
    }

    // Pitch berhasil dideteksi lagi
    _missedFrames = 0;

    // Median filter
    _freqHistory.add(freq);

    if (_freqHistory.length > _historySize) {
      _freqHistory.removeAt(0);
    }

    final sorted = [..._freqHistory]..sort();

    final medianFreq = sorted[sorted.length ~/ 2];

    final result = PitchDetector.frequencyToNote(medianFreq);

    if (result == null) {
      return;
    }

    final detected = TunerDetected(
      note: result.note,
      octave: result.octave,
      cents: result.cents,
      frequency: medianFreq,
    );

    _lastDetected = detected;

    emit(detected);
  }

  Future<void> _onStopped(TunerStopped event, Emitter<TunerState> emit) async {
    await _audioSub?.cancel();
    await _recorder.stop();

    _freqHistory.clear();
    _lastDetected = null;
    _missedFrames = 0;

    emit(TunerIdle());
  }

  @override
  Future<void> close() async {
    await _audioSub?.cancel();
    await _recorder.dispose();
    return super.close();
  }
}
