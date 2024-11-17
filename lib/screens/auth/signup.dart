import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'verification.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
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

  Future<void> _signup() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/auth/register'),
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

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          String tempUserId = data['tempUserId'];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationPage(
                email: _emailController.text,
                tempUserId: tempUserId,
              ),
            ),
          );
        } else {
          final error = jsonDecode(response.body)['error'] ?? 'Registration failed';
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                          'assets/icons/signup.png',
                          height: 100,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Create an Account",
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
                          "Sign up to get started",
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
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Username',
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
                                  prefixIcon: Icon(Icons.person, color: Colors.white70),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a username';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 20),
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
                              SizedBox(height: 20),
                              TextFormField(
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
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
                                obscureText: true,
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(height: 30),
                              _isLoading
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : ElevatedButton(
                                onPressed: _signup,
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
                                  'Sign Up',
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
                                    MaterialPageRoute(builder: (context) => LoginPage()),
                                  );
                                },
                                child: Text(
                                  "Already have an account? Log in",
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
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
