import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../components/drawer.dart';
import '../bloc/beat_bloc.dart';
import '../bloc/beat_event.dart';
import '../bloc/beat_state.dart';
import '../widgets/beat_dots_widget.dart';
import '../widgets/beat_controls_row.dart';
import '../widgets/bpm_display_widget.dart';
import '../widgets/tap_tempo_button.dart';
import '../widgets/time_signature_picker.dart';

class BeatPage extends StatelessWidget {
  const BeatPage({super.key});

  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      drawer: const MyDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          ),
        ),
        child: BlocListener<BeatBloc, BeatState>(
          listenWhen: (prev, curr) => curr.status == BeatStatus.error,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Something went wrong'),
                backgroundColor: const Color(0xFF5C1A0A),
              ),
            );
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    spacing: 10,
                    mainAxisAlignment: .spaceBetween,
                    children: [
                      Builder(
                        builder: (context) {
                          return IconButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            tooltip: 'Open Drawer App',
                            icon: const Icon(Icons.menu_rounded),
                          );
                        },
                      ),

                      const Text(
                        'BEAT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Loading indicator saat init
                      BlocBuilder<BeatBloc, BeatState>(
                        buildWhen: (p, c) => p.status != c.status,
                        builder: (context, state) {
                          if (state.status == BeatStatus.loading) {
                            return const SizedBox(
                              width: 40,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF4A3C28),
                              ),
                            );
                          }
                          return const SizedBox(width: 40);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Beat dots visualizer — signature element
                  const BeatDotsWidget(),

                  const SizedBox(height: 48),

                  // BPM display + slider
                  const BpmDisplayWidget(),

                  const SizedBox(height: 36),

                  // Play button + Tap tempo
                  Row(
                    crossAxisAlignment: .start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TapTempoButton(),
                      const SizedBox(width: 32),
                      _PlayButton(),
                    ],
                  ),

                  const Spacer(),

                  // Bottom controls
                  const TimeSignaturePicker(),
                  const SizedBox(height: 24),
                  const BeatControlsRow(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BeatBloc, BeatState>(
      buildWhen: (prev, curr) => prev.isPlaying != curr.isPlaying,
      builder: (context, state) {
        return InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            context.read<BeatBloc>().add(const BeatPlayToggled());
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.isPlaying
                  ? const Color(0xFFD4920A).withValues(alpha: 0.15)
                  : const Color(0xFF221508),
              border: Border.all(
                color: state.isPlaying
                    ? const Color(0xFFD4920A)
                    : const Color(0xFF4A3820),
                width: state.isPlaying ? 1.5 : 1,
              ),
              boxShadow: state.isPlaying
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD4920A).withValues(alpha: 0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      const BoxShadow(
                        color: Colors.black,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              state.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
              color: state.isPlaying
                  ? const Color(0xFFD4920A)
                  : const Color(0xFF6B5A3E),
              size: 32,
            ),
          ),
        );
      },
    );
  }
}
