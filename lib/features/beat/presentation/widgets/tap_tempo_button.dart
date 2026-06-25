import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/beat_bloc.dart';
import '../bloc/beat_event.dart';
import '../bloc/beat_state.dart';

class TapTempoButton extends StatefulWidget {
  const TapTempoButton({super.key});

  @override
  State<TapTempoButton> createState() => _TapTempoButtonState();
}

class _TapTempoButtonState extends State<TapTempoButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    _controller.forward().then((_) => _controller.reverse());
    context.read<BeatBloc>().add(const BeatTapTempoTapped());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) =>
          prev.tapHistory.length != curr.tapHistory.length,
      builder: (context, state) {
        // tap_tempo_button.dart — di dalam BlocBuilder
        final tapsNeeded = 4;
        final tapsLeft = (tapsNeeded - state.tapHistory.length).clamp(
          0,
          tapsNeeded,
        );
        final hint = tapsLeft > 0 ? 'Tap ${tapsLeft}x more' : 'BPM detected';

        return Column(
          children: [
            GestureDetector(
              onTap: _onTap,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4A3820),
                      width: 1.5,
                    ),
                    color: const Color(0xFF221508),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'TAP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (hint.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                style: const TextStyle(fontSize: 10, letterSpacing: 1),
              ),
            ],
          ],
        );
      },
    );
  }
}
