import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter_soloud/flutter_soloud.dart';

import '../domain/entity/beat_settings.dart';

/// State yang di-emit ke listener setiap tick beat
class BeatTickState {
  final int beatIndex; // 0-based index dalam satu bar
  final int totalBeats; // total beat per bar (dari time signature)
  final bool isAccent; // true jika downbeat (beat pertama)
  final DateTime scheduledAt;

  const BeatTickState({
    required this.beatIndex,
    required this.totalBeats,
    required this.isAccent,
    required this.scheduledAt,
  });
}

class BeatAudioService {
  BeatAudioService._();
  static final BeatAudioService instance = BeatAudioService._();

  final SoLoud _soloud = SoLoud.instance;

  // AudioSource untuk masing-masing jenis suara
  AudioSource? _accentSource; // downbeat (lebih keras / pitch lebih tinggi)
  AudioSource? _beatSource; // beat biasa

  // Stream controller untuk UI (animasi, highlight beat)
  final _tickController = StreamController<BeatTickState>.broadcast();
  Stream<BeatTickState> get tickStream => _tickController.stream;

  Timer? _timer;
  DateTime? _startTime;
  int _currentBeat = 0;
  BeatSettings _settings = const BeatSettings();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  // ─────────────────────────────────────────────
  // Init & Dispose
  // ─────────────────────────────────────────────

  Future<void> init() async {
    if (!_soloud.isInitialized) {
      await _soloud.init(
        sampleRate: 44100,
        bufferSize: 512, // buffer kecil = latency rendah
      );
    }
    await _loadSounds(_settings.soundType);
  }

  Future<void> dispose() async {
    await stop();
    await _disposeSources();
    await _tickController.close();
  }

  // ─────────────────────────────────────────────
  // Load Sounds (PCM synthesis, tidak butuh asset file)
  // ─────────────────────────────────────────────

  // Di BeatAudioService, ganti _loadSounds dan tambah generator baru

  Future<void> _loadSounds(BeatSoundType type) async {
    await _disposeSources();

    final Uint8List accentBytes;
    final Uint8List beatBytes;

    switch (type) {
      case BeatSoundType.click:
        accentBytes = _generateClickWav(
          frequency: 1200,
          durationMs: 25,
          amplitude: 0.9,
        );
        beatBytes = _generateClickWav(
          frequency: 800,
          durationMs: 20,
          amplitude: 0.7,
        );

      case BeatSoundType.woodblock:
        accentBytes = _generateWoodblockWav(
          frequency: 900,
          durationMs: 55,
          amplitude: 0.9,
        );
        beatBytes = _generateWoodblockWav(
          frequency: 600,
          durationMs: 50,
          amplitude: 0.7,
        );

      case BeatSoundType.cowbell:
        accentBytes = _generateCowbellWav(amplitude: 0.9);
        beatBytes = _generateCowbellWav(amplitude: 0.65);

      case BeatSoundType.rimshot:
        accentBytes = _generateRimshotWav(amplitude: 0.9);
        beatBytes = _generateRimshotWav(amplitude: 0.65);
    }

    _accentSource = await _soloud.loadMem(
      'beat_accent_${type.name}',
      accentBytes,
    );
    _beatSource = await _soloud.loadMem('beat_normal_${type.name}', beatBytes);
  }

  Future<void> _disposeSources() async {
    if (_accentSource != null) {
      await _soloud.disposeSource(_accentSource!);
      _accentSource = null;
    }
    if (_beatSource != null) {
      await _soloud.disposeSource(_beatSource!);
      _beatSource = null;
    }
  }

  // ─────────────────────────────────────────────
  // Playback Control
  // ─────────────────────────────────────────────

  Future<void> start(BeatSettings settings) async {
    if (_isPlaying) await stop();
    _settings = settings;

    // Reload suara jika sound type berubah
    if (_accentSource == null || _beatSource == null) {
      await _loadSounds(settings.soundType);
    }

    _currentBeat = 0;
    _isPlaying = true;
    _startTime = DateTime.now();

    // Mainkan beat pertama segera
    await _tick();

    // Schedule beat berikutnya dengan clock-anchored timing
    _scheduleNextBeat();
  }

  Future<void> stop() async {
    _isPlaying = false;
    _timer?.cancel();
    _timer = null;
    _currentBeat = 0;
    _startTime = null;
  }

  Future<void> updateSettings(BeatSettings newSettings) async {
    final wasPlaying = _isPlaying;
    final soundChanged = newSettings.soundType != _settings.soundType;

    _settings = newSettings;

    if (soundChanged) {
      await _loadSounds(newSettings.soundType);
    }

    if (wasPlaying) {
      // Restart dengan settings baru; reset phase agar tidak glitch
      await stop();
      await start(newSettings);
    }
  }

  // ─────────────────────────────────────────────
  // Clock-Anchored Scheduling
  // ─────────────────────────────────────────────

  void _scheduleNextBeat() {
    if (!_isPlaying || _startTime == null) return;

    // Hitung kapan beat BERIKUTNYA seharusnya berbunyi secara absolut
    final nextBeatIndex = _currentBeat + 1;
    final nextBeatTime = _startTime!.add(
      Duration(
        microseconds: (nextBeatIndex * _settings.intervalSeconds * 1e6).round(),
      ),
    );

    final now = DateTime.now();
    final delay = nextBeatTime.difference(now);

    // Jika sudah lewat (lag spike), langsung tick tanpa delay
    final safeDuration = delay.isNegative ? Duration.zero : delay;

    _timer = Timer(safeDuration, () async {
      if (!_isPlaying) return;
      _currentBeat = nextBeatIndex;
      await _tick();
      _scheduleNextBeat();
    });
  }

  Future<void> _tick() async {
    if (!_isPlaying) return;

    final totalBeats = _settings.timeSignature.value;
    final beatInBar = _currentBeat % totalBeats;
    final isAccent = _settings.accentFirstBeat && beatInBar == 0;

    // Play audio
    final source = isAccent ? _accentSource : _beatSource;
    if (source != null) {
      final handle = _soloud.play(
        source,
        volume: isAccent ? _settings.volume : _settings.volume * 0.75,
        paused: false,
      );
      // Auto-stop setelah 100ms agar tidak tumpuk-tumpuk di BPM tinggi
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          _soloud.stop(handle);
        } catch (_) {}
      });
    }

    // Emit ke stream untuk UI
    _tickController.add(
      BeatTickState(
        beatIndex: beatInBar,
        totalBeats: totalBeats,
        isAccent: isAccent,
        scheduledAt: DateTime.now(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PCM WAV Generator (tidak butuh asset file!)
  // ─────────────────────────────────────────────

  /// Generate WAV click sound secara programatik.
  /// Menggunakan sine wave pendek dengan envelope decay cepat.
  /// CLICK — sine pendek, decay sangat cepat (metronome klasik)
  Uint8List _generateClickWav({
    required double frequency,
    required int durationMs,
    required double amplitude,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, sampleRate: sampleRate, dataSize: dataSize);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * (1000 / durationMs) * 4);
      final sample =
          amplitude * envelope * math.sin(2 * math.pi * frequency * t);
      buffer.setInt16(
        offset,
        (sample * 32767).clamp(-32768, 32767).toInt(),
        Endian.little,
      );
      offset += 2;
    }
    return buffer.buffer.asUint8List();
  }

  /// WOODBLOCK — dua sine digabung (resonansi kayu) + decay lebih panjang
  Uint8List _generateWoodblockWav({
    required double frequency,
    required int durationMs,
    required double amplitude,
  }) {
    const sampleRate = 44100;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, sampleRate: sampleRate, dataSize: dataSize);

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Karakter kayu: dua frekuensi (fundamental + overtone 2.76x)
      // Decay lebih lambat dari click — kayu bergema
      final envelope = math.exp(-t * 60);
      final wave =
          (math.sin(2 * math.pi * frequency * t) * 0.7) +
          (math.sin(2 * math.pi * frequency * 2.76 * t) * 0.3);
      final sample = amplitude * envelope * wave;
      buffer.setInt16(
        offset,
        (sample * 32767).clamp(-32768, 32767).toInt(),
        Endian.little,
      );
      offset += 2;
    }
    return buffer.buffer.asUint8List();
  }

  /// COWBELL — dua square wave detuned + metallic decay panjang
  Uint8List _generateCowbellWav({required double amplitude}) {
    const sampleRate = 44100;
    const durationMs = 400; // cowbell bergema lama
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, sampleRate: sampleRate, dataSize: dataSize);

    // Frekuensi khas cowbell: 562 Hz + 845 Hz (rasio ~1.5, bukan harmonik murni)
    const f1 = 562.0;
    const f2 = 845.0;

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Square wave = karakter metalik lebih kuat dari sine
      final sq1 = math.sin(2 * math.pi * f1 * t) >= 0 ? 1.0 : -1.0;
      final sq2 = math.sin(2 * math.pi * f2 * t) >= 0 ? 1.0 : -1.0;

      // Cowbell: attack cepat, decay eksponensial lambat
      final envelope = math.exp(-t * 8);
      final wave = (sq1 * 0.6 + sq2 * 0.4);
      final sample =
          amplitude * envelope * wave * 0.5; // *0.5 karena square keras

      buffer.setInt16(
        offset,
        (sample * 32767).clamp(-32768, 32767).toInt(),
        Endian.little,
      );
      offset += 2;
    }
    return buffer.buffer.asUint8List();
  }

  /// RIMSHOT — noise burst pendek + transient "snap"
  Uint8List _generateRimshotWav({required double amplitude}) {
    const sampleRate = 44100;
    const durationMs = 80;
    final numSamples = (sampleRate * durationMs / 1000).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeWavHeader(buffer, sampleRate: sampleRate, dataSize: dataSize);

    final rng = math.Random(42); // seed tetap agar suara konsisten

    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;

      // Rimshot = white noise (karakter "snap" plastik) + tone rendah singkat
      final noise = (rng.nextDouble() * 2 - 1);
      final tone = math.sin(2 * math.pi * 200 * t); // body drum rendah

      // Dua layer envelope:
      // - snap: decay sangat cepat (transient attack)
      // - body: decay sedikit lebih lambat
      final snapEnv = math.exp(-t * 200); // habis dalam ~5ms
      final bodyEnv = math.exp(-t * 40); // habis dalam ~25ms

      final wave = (noise * snapEnv * 0.7) + (tone * bodyEnv * 0.3);
      final sample = amplitude * wave;

      buffer.setInt16(
        offset,
        (sample * 32767).clamp(-32768, 32767).toInt(),
        Endian.little,
      );
      offset += 2;
    }
    return buffer.buffer.asUint8List();
  }

  /// Helper: tulis WAV header 44-byte ke ByteData yang sudah dialokasi
  void _writeWavHeader(
    ByteData buffer, {
    required int sampleRate,
    required int dataSize,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    int o = 0;
    // "RIFF"
    buffer.setUint8(o++, 0x52);
    buffer.setUint8(o++, 0x49);
    buffer.setUint8(o++, 0x46);
    buffer.setUint8(o++, 0x46);
    buffer.setUint32(o, 36 + dataSize, Endian.little);
    o += 4;
    // "WAVE"
    buffer.setUint8(o++, 0x57);
    buffer.setUint8(o++, 0x41);
    buffer.setUint8(o++, 0x56);
    buffer.setUint8(o++, 0x45);
    // "fmt "
    buffer.setUint8(o++, 0x66);
    buffer.setUint8(o++, 0x6D);
    buffer.setUint8(o++, 0x74);
    buffer.setUint8(o++, 0x20);
    buffer.setUint32(o, 16, Endian.little);
    o += 4; // Subchunk1Size
    buffer.setUint16(o, 1, Endian.little);
    o += 2; // PCM format
    buffer.setUint16(o, channels, Endian.little);
    o += 2;
    buffer.setUint32(o, sampleRate, Endian.little);
    o += 4;
    buffer.setUint32(
      o,
      sampleRate * channels * bitsPerSample ~/ 8,
      Endian.little,
    );
    o += 4;
    buffer.setUint16(o, channels * bitsPerSample ~/ 8, Endian.little);
    o += 2;
    buffer.setUint16(o, bitsPerSample, Endian.little);
    o += 2;
    // "data"
    buffer.setUint8(o++, 0x64);
    buffer.setUint8(o++, 0x61);
    buffer.setUint8(o++, 0x74);
    buffer.setUint8(o++, 0x61);
    buffer.setUint32(o, dataSize, Endian.little);
  }
}
