import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/home_page.dart';

void main() {
  runApp(const TempoApp());
}

class TempoApp extends StatelessWidget {
  const TempoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tempo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C1C1E),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF2F2F2),
        fontFamily: GoogleFonts.inter().fontFamily,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
