import 'dart:math';

class PitchDetector {
  static const double sampleRate = 44100.0;
  static const double minFreq = 70.0; // E2 gitar
  static const double maxFreq = 1400.0; // E6 gitar
  static const double yinThreshold = 0.10; // lebih rendah = lebih ketat

  static const List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  /// YIN pitch detection — akurasi ±1-2 cents
  static double? detectPitch(List<double> buffer) {
    // 1. Noise gate
    double rms = 0;
    for (final s in buffer) {
      rms += s * s;
    }
    rms = sqrt(rms / buffer.length);
    if (rms < 0.015) return null;

    final n = buffer.length;
    final halfN = n ~/ 2;

    // 2. Hann window
    final windowed = List<double>.generate(n, (i) {
      final w = 0.5 * (1 - cos(2 * pi * i / (n - 1)));
      return buffer[i] * w;
    });

    // 3. Difference function: d(τ) = Σ(x[t] - x[t+τ])²
    final diff = List<double>.filled(halfN, 0.0);
    for (int tau = 1; tau < halfN; tau++) {
      double sum = 0.0;
      for (int t = 0; t < halfN; t++) {
        final delta = windowed[t] - windowed[t + tau];
        sum += delta * delta;
      }
      diff[tau] = sum;
    }

    // 4. Cumulative Mean Normalized Difference Function (CMNDF)
    // Ini kunci YIN — mencegah false octave di lag kecil
    final cmndf = List<double>.filled(halfN, 0.0);
    cmndf[0] = 1.0;
    double cumSum = 0.0;
    for (int tau = 1; tau < halfN; tau++) {
      cumSum += diff[tau];
      cmndf[tau] = cumSum > 0 ? diff[tau] * tau / cumSum : 1.0;
    }

    // 5. Cari tau minimum yang melewati threshold
    final minTau = (sampleRate / maxFreq).ceil();
    final maxTau = (sampleRate / minFreq).floor().clamp(1, halfN - 1);

    int bestTau = -1;
    for (int tau = minTau; tau <= maxTau; tau++) {
      if (cmndf[tau] < yinThreshold) {
        // Ambil minimum lokal di sekitar titik ini
        while (tau + 1 <= maxTau && cmndf[tau + 1] < cmndf[tau]) {
          tau++;
        }
        bestTau = tau;
        break;
      }
    }

    // Fallback: ambil minimum global jika tidak ada yang di bawah threshold
    if (bestTau == -1) {
      double minVal = double.infinity;
      for (int tau = minTau; tau <= maxTau; tau++) {
        if (cmndf[tau] < minVal) {
          minVal = cmndf[tau];
          bestTau = tau;
        }
      }
      // Kalau minimum globalnya masih terlalu tinggi, sinyal tidak valid
      if (minVal > 0.35) return null;
    }

    if (bestTau == -1 || bestTau <= 0 || bestTau >= halfN - 1) return null;

    // 6. Parabolic interpolation — presisi sub-sample
    final y0 = cmndf[bestTau - 1];
    final y1 = cmndf[bestTau];
    final y2 = cmndf[bestTau + 1];
    final denom = 2 * y1 - y0 - y2;
    final refinedTau = denom != 0
        ? bestTau + (y2 - y0) / (2 * denom)
        : bestTau.toDouble();

    return sampleRate / refinedTau;
  }

  /// Konversi Hz → nama nada + oktaf + cents
  static ({String note, int octave, double cents})? frequencyToNote(
    double freq,
  ) {
    if (freq <= 0 || freq.isNaN || freq.isInfinite) return null;

    final noteNum = 12 * log(freq / 440.0) / log(2) + 69;
    int rounded = noteNum.round();
    double cents = (noteNum - rounded) * 100;

    if (cents > 50) {
      cents -= 100;
      rounded += 1;
    }
    if (cents < -50) {
      cents += 100;
      rounded -= 1;
    }

    final octave = (rounded ~/ 12) - 1;
    final note = noteNames[rounded % 12];

    return (note: note, octave: octave, cents: cents);
  }
}
