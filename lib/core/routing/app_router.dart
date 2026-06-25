import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/beat/presentation/bloc/beat_bloc.dart';
import '../../features/beat/presentation/pages/beat_page.dart';
import '../../features/tuner/presentation/bloc/tuner_bloc.dart';
import '../../features/tuner/presentation/pages/tuner_page.dart';
import '../config/injection.dart';
import 'app_path.dart';

final appRouter = GoRouter(
  initialLocation: AppPath.tuner,
  routes: [
    GoRoute(
      path: AppPath.tuner,
      builder: (context, state) {
        return BlocProvider(
          create: (_) => TunerBloc(),
          child: const TunerPage(),
        );
      },
    ),
    GoRoute(
      path: AppPath.beat,
      builder: (context, state) {
        return BlocProvider(
          create: (_) => sl<BeatBloc>(),
          child: const BeatPage(),
        );
      },
    ),
  ],
);
