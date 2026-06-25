import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/beat_settings.dart';
import '../bloc/beat_bloc.dart';
import '../bloc/beat_event.dart';
import '../bloc/beat_state.dart';

class BeatControlsRow extends StatelessWidget {
  const BeatControlsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) =>
          prev.settings.soundType != curr.settings.soundType ||
          prev.settings.accentFirstBeat != curr.settings.accentFirstBeat ||
          prev.settings.volume != curr.settings.volume,
      builder: (context, state) {
        return Column(
          children: [
            // Sound type selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 2, bottom: 10),
                  child: Text(
                    'SOUND',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  children: BeatSoundType.values.map((type) {
                    final isSelected = state.settings.soundType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _SoundChip(
                        label: _soundLabel(type),
                        isSelected: isSelected,
                        onTap: () => context.read<BeatBloc>().add(
                          BeatSoundTypeChanged(type),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Accent toggle + Volume row
            Row(
              children: [
                // Accent toggle
                GestureDetector(
                  onTap: () =>
                      context.read<BeatBloc>().add(const BeatAccentToggled()),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 36,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: state.settings.accentFirstBeat
                              ? const Color(0xFFD4920A).withValues(alpha: 0.3)
                              : const Color(0xFF1E1308),
                          border: Border.all(
                            color: state.settings.accentFirstBeat
                                ? const Color(0xFFD4920A)
                                : const Color(0xFF2E2010),
                          ),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: state.settings.accentFirstBeat
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 14,
                            height: 14,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.settings.accentFirstBeat
                                  ? const Color(0xFFD4920A)
                                  : const Color(0xFF4A3C28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ACCENT',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Volume icon + slider compact
                const Icon(Icons.volume_up_rounded, size: 16),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.orangeAccent,
                      inactiveTrackColor: Colors.orangeAccent.withValues(
                        alpha: .5,
                      ),
                      thumbColor: const Color(0xFFD4920A),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 5,
                      ),
                      trackHeight: 1.5,
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: state.settings.volume,
                      onChanged: (v) =>
                          context.read<BeatBloc>().add(BeatVolumeChanged(v)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  String _soundLabel(BeatSoundType type) => switch (type) {
    BeatSoundType.click => 'Click',
    BeatSoundType.woodblock => 'Wood',
    BeatSoundType.cowbell => 'Cowbell',
    BeatSoundType.rimshot => 'Rim',
  };
}

class _SoundChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SoundChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected
              ? const Color(0xFFD4920A).withValues(alpha: 0.15)
              : const Color(0xFF1E1308),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4920A)
                : const Color(0xFF2E2010),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? const Color(0xFFD4920A)
                : const Color(0xFF4A3C28),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
