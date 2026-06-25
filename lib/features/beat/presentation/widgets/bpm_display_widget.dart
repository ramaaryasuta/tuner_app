import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/beat_settings.dart';
import '../bloc/beat_bloc.dart';
import '../bloc/beat_event.dart';
import '../bloc/beat_state.dart';

class BpmDisplayWidget extends StatelessWidget {
  const BpmDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) =>
          prev.displayBpm != curr.displayBpm ||
          prev.isPlaying != curr.isPlaying,
      builder: (context, state) {
        return Column(
          children: [
            // BPM number
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${state.displayBpm}',
                    style: const TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const TextSpan(
                    text: '\nbpm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tempo label (Largo, Andante, Allegro, dll.)
            Text(
              _tempoLabel(state.displayBpm),
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 20),

            // BPM Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Colors.orangeAccent,
                  inactiveTrackColor: Colors.orangeAccent.withValues(alpha: .5),
                  thumbColor: const Color(0xFFD4920A),
                  overlayColor: const Color(0xFFD4920A).withValues(alpha: .2),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  trackHeight: 2,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 18,
                  ),
                ),
                child: Slider(
                  value: state.displayBpm.toDouble(),
                  min: BeatSettings.minBpm.toDouble(),
                  max: BeatSettings.maxBpm.toDouble(),
                  onChanged: (v) {
                    context.read<BeatBloc>().add(BeatBpmChanged(v.round()));
                  },
                ),
              ),
            ),

            // Min/Max labels
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${BeatSettings.minBpm}',
                    style: TextStyle(fontSize: 11, letterSpacing: 1),
                  ),
                  Text(
                    '${BeatSettings.maxBpm}',
                    style: TextStyle(fontSize: 11, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _tempoLabel(int bpm) {
    if (bpm < 40) return 'GRAVE';
    if (bpm < 60) return 'LARGO';
    if (bpm < 66) return 'LARGHETTO';
    if (bpm < 76) return 'ADAGIO';
    if (bpm < 108) return 'ANDANTE';
    if (bpm < 120) return 'MODERATO';
    if (bpm < 156) return 'ALLEGRO';
    if (bpm < 176) return 'VIVACE';
    if (bpm < 200) return 'PRESTO';
    return 'PRESTISSIMO';
  }
}
