import 'dart:async';

import 'package:flutter/material.dart';
import 'core/config/injection.dart';
import 'core/routing/app_router.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // setup depedency injection before app launch
    await initializeInjection();

    runApp(const MyApp());
  }, (e, s) {});
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sound Tuner',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
    );
  }
}
