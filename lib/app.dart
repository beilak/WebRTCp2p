import 'package:flutter/material.dart';

import 'screens/home_page.dart';

class WebRtcP2pDemoApp extends StatelessWidget {
  const WebRtcP2pDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF446CFF),
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'WebRTC P2P Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          centerTitle: false,
          elevation: 0,
          foregroundColor: Color(0xFF151A2D),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}
