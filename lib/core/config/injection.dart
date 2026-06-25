import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/beat/data/repositories/beat_settings_repo_impl.dart';
import '../../features/beat/domain/repository/beat_setting_repository.dart';
import '../../features/beat/domain/usecase/start_beat_usecase.dart';
import '../../features/beat/domain/usecase/stop_beat_usecase.dart';
import '../../features/beat/domain/usecase/update_beat_settings_usecase.dart';
import '../../features/beat/presentation/bloc/beat_bloc.dart';
import '../../features/beat/presentation/bloc/beat_event.dart';
import '../../features/beat/services/beat_audio_service.dart';

final sl = GetIt.instance;

Future<void> initializeInjection() async {
  // ── External ───────────────────────────────────────────────────────────────
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // ── Beat: Services ─────────────────────────────────────────────────────────
  // BeatAudioService adalah singleton internal, kita ekspos via get_it
  // agar mudah di-mock saat testing
  sl.registerSingleton<BeatAudioService>(BeatAudioService.instance);

  // ── Beat: Repositories ─────────────────────────────────────────────────────
  sl.registerSingleton<BeatSettingsRepository>(
    BeatSettingsRepositoryImpl(sl<SharedPreferences>()),
  );

  // ── Beat: Use Cases ────────────────────────────────────────────────────────
  // Didaftarkan sebagai Factory karena stateless — boleh juga LazySingleton
  sl.registerFactory<StartBeatUsecase>(
    () => StartBeatUsecase(sl<BeatAudioService>()),
  );
  sl.registerFactory<StopBeatUsecase>(
    () => StopBeatUsecase(sl<BeatAudioService>()),
  );
  sl.registerFactory<UpdateBeatSettingsUsecase>(
    () => UpdateBeatSettingsUsecase(
      sl<BeatSettingsRepository>(),
      sl<BeatAudioService>(),
    ),
  );

  // ── Beat: BLoC ─────────────────────────────────────────────────────────────
  // Factory agar setiap kali halaman dibuka dapat instance baru yang bersih.
  // BeatAudioService tetap singleton di bawahnya jadi audio tidak putus.
  sl.registerFactory<BeatBloc>(
    () => BeatBloc(
      repository: sl<BeatSettingsRepository>(),
      startBeat: sl<StartBeatUsecase>(),
      stopBeat: sl<StopBeatUsecase>(),
      updateSettings: sl<UpdateBeatSettingsUsecase>(),
      audioService: sl<BeatAudioService>(),
    )..add(const BeatInitialized()),
  );
}
