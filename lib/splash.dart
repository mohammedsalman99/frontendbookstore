import 'package:flutter/material.dart';
import 'dart:async';
import 'package:frontend/onboarding.dart'; // Import OnboardingScreen
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double>? _horizontalScaleAnimation;
  Animation<double>? _fadeAnimation;
  Animation<Color?>? _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController with 4-second duration
    _controller = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    // Horizontal scale animation for the "book opening" effect
    _horizontalScaleAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Fade animation for the app name
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Background color animation
    _backgroundColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.lightBlueAccent,
    ).animate(_controller);

    // Start the animation
    _controller.forward();

    // Navigate to the OnboardingScreen after 4 seconds
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen()), // Navigate to OnboardingScreen
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: _backgroundColorAnimation!.value,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Applying horizontal scale animation to the icon for "book opening"
                Transform.scale(
                  scaleX: _horizontalScaleAnimation!.value, // Horizontal scaling only
                  scaleY: 1.0, // Keep vertical scale constant
                  child: Icon(
                    Icons.book, // Book icon for the bookstore theme
                    size: 100.0,
                    color: Colors.blueAccent,
                  ),
                ),
                SizedBox(height: 20),
                // Progress line below the book icon, filling over 4 seconds
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: LinearProgressIndicator(
                    value: _controller.value, // Synchronizes with the controller
                    backgroundColor: Colors.grey[300], // Color when empty
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent), // Color when filled
                  ),
                ),
                SizedBox(height: 20),
                // Applying fade animation to the app name with Google Fonts
                FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Text(
                    "BookStore", // Replace with your app name
                    style: GoogleFonts.montserrat(
                      textStyle: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
