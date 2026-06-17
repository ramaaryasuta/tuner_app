import 'package:equatable/equatable.dart';

abstract class TunerState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TunerIdle extends TunerState {}

class TunerListening extends TunerState {}

class TunerDetected extends TunerState {
  final String note;
  final int octave;
  final double cents;
  final double frequency;

  TunerDetected({
    required this.note,
    required this.octave,
    required this.cents,
    required this.frequency,
  });

  @override
  List<Object?> get props => [note, octave, cents, frequency];
}

class TunerNoSignal extends TunerState {}
