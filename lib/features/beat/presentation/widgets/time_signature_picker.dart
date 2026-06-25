import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/beat_settings.dart';
import '../bloc/beat_bloc.dart';
import '../bloc/beat_event.dart';
import '../bloc/beat_state.dart';

class TimeSignaturePicker extends StatelessWidget {
  const TimeSignaturePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) =>
          prev.settings.timeSignature != curr.settings.timeSignature,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                'TIME SIGNATURE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TimeSignatureNumerator.values.map((sig) {
                  final isSelected = state.settings.timeSignature == sig;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _SignatureChip(
                      label: '${sig.value}/4',
                      isSelected: isSelected,
                      onTap: () => context.read<BeatBloc>().add(
                        BeatTimeSignatureChanged(sig),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SignatureChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SignatureChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isSelected
              ? const Color(0xFFD4920A).withValues(alpha: .15)
              : const Color(0xFF1E1308),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD4920A)
                : const Color(0xFF2E2010),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            color: isSelected
                ? const Color(0xFFD4920A)
                : const Color(0xFF4A3C28),
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
