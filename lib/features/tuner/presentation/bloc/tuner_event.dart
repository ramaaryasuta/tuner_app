abstract class TunerEvent {}

class TunerStarted extends TunerEvent {}

class TunerStopped extends TunerEvent {}

class TunerAudioReceived extends TunerEvent {
  final List<double> samples;
  TunerAudioReceived(this.samples);
}
