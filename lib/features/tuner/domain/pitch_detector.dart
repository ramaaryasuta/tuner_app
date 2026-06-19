import 'dart:math';

class PitchDetector {
  static const double sampleRate = 44100.0;
  static const double minFreq = 70.0;
  static const double maxFreq = 1400.0;
  static const double yinThreshold = 0.10;

  // Hardcode konstanta untuk presisi maksimal
  static const double _ln2 = 0.6931471805599453;
  static const double _ln440 = 6.087685849117688; // log(440.0)

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

    // 2. Hann window — gunakan `n` bukan `n-1` (lebih sesuai referensi YIN)
    final windowed = List<double>.generate(n, (i) {
      final w = 0.5 * (1.0 - cos(2.0 * pi * i / n));
      return buffer[i] * w;
    });

    // 3. Difference function
    final diff = List<double>.filled(halfN, 0.0);
    for (int tau = 1; tau < halfN; tau++) {
      double sum = 0.0;
      for (int t = 0; t < halfN; t++) {
        final delta = windowed[t] - windowed[t + tau];
        sum += delta * delta;
      }
      diff[tau] = sum;
    }

    // 4. CMNDF — hanya untuk deteksi threshold
    final cmndf = List<double>.filled(halfN, 0.0);
    cmndf[0] = 1.0;
    double cumSum = 0.0;
    for (int tau = 1; tau < halfN; tau++) {
      cumSum += diff[tau];
      cmndf[tau] = cumSum > 0 ? diff[tau] * tau / cumSum : 1.0;
    }

    // 5. Cari bestTau via CMNDF (tidak berubah)
    final minTau = (sampleRate / maxFreq).ceil();
    final maxTau = (sampleRate / minFreq).floor().clamp(1, halfN - 1);

    int bestTau = -1;
    for (int tau = minTau; tau <= maxTau; tau++) {
      if (cmndf[tau] < yinThreshold) {
        while (tau + 1 <= maxTau && cmndf[tau + 1] < cmndf[tau]) {
          tau++;
        }
        bestTau = tau;
        break;
      }
    }

    if (bestTau == -1) {
      double minVal = double.infinity;
      for (int tau = minTau; tau <= maxTau; tau++) {
        if (cmndf[tau] < minVal) {
          minVal = cmndf[tau];
          bestTau = tau;
        }
      }
      if (minVal > 0.35) return null;
    }

    if (bestTau == -1 || bestTau <= 0 || bestTau >= halfN - 1) return null;

    // 6. ✅ Parabolic interpolation pada diff mentah, bukan CMNDF
    final y0 = diff[bestTau - 1];
    final y1 = diff[bestTau];
    final y2 = diff[bestTau + 1];
    final denom = 2.0 * y1 - y0 - y2;
    final refinedTau = denom > 1e-10
        ? bestTau + (y2 - y0) / (2.0 * denom)
        : bestTau.toDouble();

    return sampleRate / refinedTau;
  }

  static ({String note, int octave, double cents})? frequencyToNote(
    double freq,
  ) {
    if (freq <= 0 || freq.isNaN || freq.isInfinite) return null;

    // ✅ Gunakan ln hardcoded untuk presisi
    final noteNum = 12.0 * (log(freq) - _ln440) / _ln2 + 69.0;
    int rounded = noteNum.round();
    double cents = (noteNum - rounded) * 100.0;

    if (cents > 50.0) {
      cents -= 100.0;
      rounded += 1;
    }
    if (cents < -50.0) {
      cents += 100.0;
      rounded -= 1;
    }

    final octave = (rounded ~/ 12) - 1;
    final note = noteNames[rounded % 12];

    return (note: note, octave: octave, cents: cents);
  }
}
