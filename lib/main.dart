import 'package:flutter/material.dart';
import 'features/tuner/presentation/pages/tuner_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TunerApp());
}

class TunerApp extends StatelessWidget {
  const TunerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sound Tuner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TunerPage(),
    );
  }
}
