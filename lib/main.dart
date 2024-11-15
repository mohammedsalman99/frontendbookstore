import 'package:flutter/material.dart';
import 'package:frontend/splash.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BookStore',
      home: SplashScreen(), // Start with SplashScreen
    );
  }
}