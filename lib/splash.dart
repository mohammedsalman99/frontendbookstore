import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding.dart'; 
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

    _controller = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    );

    _horizontalScaleAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    _backgroundColorAnimation = ColorTween(
      begin: Colors.white,
      end: Color(0xFF5AA5B1),
    ).animate(_controller);

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => OnboardingScreen()), 
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
                Transform.scale(
                  scaleX: _horizontalScaleAnimation!.value, 
                  scaleY: 1.0, 
                  child: Icon(
                    Icons.book, 
                    size: 100.0,
                    color: Color(0xFF5AA5B1),
                  ),
                ),
                SizedBox(height: 20),
               
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 40.0),
                  child: LinearProgressIndicator(
                    value: _controller.value, 
                    backgroundColor: Colors.grey[300], 
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5AA5B1)), 
                  ),
                ),
                SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation!,
                  child: Text(
                    "", 
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
