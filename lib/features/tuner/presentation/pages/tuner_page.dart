import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../components/drawer.dart';
import '../bloc/tuner_bloc.dart';
import '../bloc/tuner_event.dart';
import '../bloc/tuner_state.dart';
import '../widgets/cents_meter.dart';

class TunerPage extends StatelessWidget {
  const TunerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _TunerView();
  }
}

class _TunerView extends StatelessWidget {
  const _TunerView();

  @override
  Widget build(BuildContext context) {
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
        child: SafeArea(
          child: BlocBuilder<TunerBloc, TunerState>(
            builder: (context, state) {
              final detected = state is TunerDetected;

              final cents = detected ? state.cents : 0.0;

              final isListening =
                  state is TunerListening ||
                  state is TunerDetected ||
                  state is TunerNoSignal;

              Color statusColor;
              String statusText;

              if (!isListening) {
                statusColor = Colors.white54;
                statusText = 'READY';
              } else if (cents.abs() <= 10) {
                statusColor = Colors.greenAccent;
                statusText = 'IN TUNE';
              } else if (cents > 0) {
                statusColor = Colors.orangeAccent;
                statusText = 'TOO SHARP';
              } else {
                statusColor = Colors.orangeAccent;
                statusText = 'TOO FLAT';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      spacing: 10,
                      mainAxisAlignment: .spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          tooltip: 'Open Drawer App',
                          icon: const Icon(Icons.menu_rounded),
                        ),

                        const Text(
                          'SOUND TUNER',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(width: 40),
                      ],
                    ),
                    const Spacer(),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 150),
                      style: const TextStyle(
                        fontSize: 96,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                      child: Text(
                        detected ? '${state.note}${state.octave}' : '--',
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      detected
                          ? '${state.frequency.toStringAsFixed(1)} Hz'
                          : 'Waiting microphone...',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),

                    const SizedBox(height: 24),

                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .05),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .1),
                        ),
                      ),
                      child: CentsMeter(cents: cents),
                    ),

                    const Spacer(),

                    GestureDetector(
                      onTap: () {
                        final bloc = context.read<TunerBloc>();

                        if (isListening) {
                          bloc.add(TunerStopped());
                        } else {
                          bloc.add(TunerStarted());
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: isListening
                                ? [Colors.red, Colors.redAccent]
                                : [Colors.green, Colors.greenAccent],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? Colors.red : Colors.green)
                                  .withValues(alpha: .45),
                              blurRadius: 25,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.stop_rounded : Icons.mic,
                          color: Colors.white,
                          size: 42,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      isListening ? 'Tap to Stop' : 'Tap to Start',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
