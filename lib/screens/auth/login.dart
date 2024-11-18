import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup.dart';
import '../Home/home.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 600));
    _animationController.forward();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/auth/login'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        setState(() {
          _isLoading = false;
        });

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          String token = data['token'];


          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Home()), 
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Login successful!',
                style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'Login failed';
          _showError(error);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showError('An error occurred. Please try again.');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5AA5B1), Color(0xFF3D7A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 24.0),
                    padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/icons/login.png',
                          height: 100,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 3),
                                blurRadius: 10,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Login to continue",
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 30),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  labelStyle: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.email, color: Colors.white70),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white70,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  prefixIcon: Icon(Icons.lock, color: Colors.white70),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.white70,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                ),
                                obscureText: !_isPasswordVisible,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  } else if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 30),
                              _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF5AA5B1),
                                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  shadowColor: Colors.black26,
                                  elevation: 10,
                                ),
                                child: Text(
                                  'Login',
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => SignupPage()),
                                  );
                                },
                                child: Text(
                                  "Don't have an account? Sign up",
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                "or connect with",
                                style: TextStyle(
                                  fontFamily: 'SF-Pro-Text',
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Image.asset('assets/icons/google.png', color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: Image.asset('assets/icons/facebook.png', color: Colors.white),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: Image.asset('assets/icons/apple.png', color: Colors.white),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
