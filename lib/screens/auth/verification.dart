import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Home/home.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class VerificationPage extends StatefulWidget {
  final String email;
  final String tempUserId;

  VerificationPage({required this.email, required this.tempUserId});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;


  Future<bool> _verifyCode(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tempUserId': widget.tempUserId,
          'verificationCode': code,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        String token = responseData['token'];
        String userId = responseData['user']['id'];
        String userEmail = responseData['user']['email'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_id', userId);
        await prefs.setString('user_email', userEmail);

        print('Verification successful. Token: $token');
        return true;
      } else {
        final error = jsonDecode(response.body)['message'] ?? 'Invalid verification code';
        print('Verification failed: $error');
        _showError(error);
        return false;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error during verification: $e');
      _showError("An error occurred. Please try again.");
      return false;
    }
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

  void _submitCode() async {
    if (_codeController.text.isEmpty) {
      _showError("Please enter the verification code");
      return;
    }

    bool isValid = await _verifyCode(_codeController.text);

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification successful!',
            style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError("Invalid verification code");
    }
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
                    margin: const EdgeInsets.symmetric(horizontal: 20.0),
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 70,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 10),

                        Text(
                          "Email Verification",
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          "A verification code has been sent to ${widget.email}. Please enter the code below to verify your email.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.text, 
                          decoration: InputDecoration(
                            labelText: "Verification Code",
                            labelStyle: TextStyle(color: Colors.white70, fontSize: 11),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: Icon(Icons.lock, color: Colors.white70),
                          ),
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),

                        const SizedBox(height: 12),

                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : ElevatedButton(
                          onPressed: _submitCode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5AA5B1),
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Verify",
                            style: TextStyle(
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Verification code resent to ${widget.email}",
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            "Resend Code",
                            style: TextStyle(
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              fontSize: 12,
                            ),
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
