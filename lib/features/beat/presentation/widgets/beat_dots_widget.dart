import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entity/beat_settings.dart';
import '../bloc/beat_bloc.dart';
import '../bloc/beat_state.dart';

class BeatDotsWidget extends StatelessWidget {
  const BeatDotsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) =>
          prev.activeBeatIndex != curr.activeBeatIndex ||
          prev.settings.timeSignature != curr.settings.timeSignature ||
          prev.isPlaying != curr.isPlaying,
      builder: (context, state) {
        final totalBeats = state.settings.timeSignature.value;
        final activeIndex = state.activeBeatIndex;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalBeats, (i) {
            final isActive = state.isPlaying && activeIndex == i;
            final isAccent = i == 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _BeatDot(isActive: isActive, isAccent: isAccent),
            );
          }),
        );
      },
    );
  }
}

class _BeatDot extends StatefulWidget {
  final bool isActive;
  final bool isAccent;

  const _BeatDot({required this.isActive, required this.isAccent});

  @override
  State<_BeatDot> createState() => _BeatDotState();
}

class _BeatDotState extends State<_BeatDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.45,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_BeatDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // Trigger pulse: forward lalu balik
      _controller.forward().then((_) => _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Accent dot lebih besar dari beat biasa
    final baseSize = widget.isAccent ? 18.0 : 13.0;

    final dotColor = widget.isAccent
        ? const Color(0xFFD4920A) // amber gold — downbeat
        : const Color(0xFF8B6914); // amber redup — beat biasa

    final activeColor = widget.isAccent
        ? const Color(0xFFFFBF3C)
        : Colors.orangeAccent;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final glowRadius = _glowAnim.value * (widget.isAccent ? 14.0 : 10.0);
        final currentColor = Color.lerp(
          dotColor,
          activeColor,
          _glowAnim.value,
        )!;

        return Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            width: baseSize,
            height: baseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: currentColor,
              boxShadow: glowRadius > 0
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: .6),
                        blurRadius: glowRadius,
                        spreadRadius: glowRadius * 0.3,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      },
    );
  }
}
