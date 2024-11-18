import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Home/home.dart';

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

  // Function to handle API call for verifying code
  Future<bool> _verifyCode(String code) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/auth/verify-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'tempUserId': widget.tempUserId,
          'verificationCode': code,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        // If the response is OK, return true
        return true;
      } else {
        // If the response is an error, show error message
        final error = jsonDecode(response.body)['message'] ?? 'Invalid verification code';
        _showError(error);
        return false;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError("An error occurred. Please try again.");
      return false;
    }
  }

  // Function to display error messages
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

  // Function to handle form submission
  void _submitCode() async {
    if (_codeController.text.isEmpty) {
      _showError("Please enter the verification code");
      return;
    }

    bool isValid = await _verifyCode(_codeController.text);

    if (isValid) {
      // Navigate to home screen if verification is successful
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Home()),
      );
    } else {
      _showError("Invalid verification code");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        Icon(
                          Icons.mail_outline,
                          size: 100,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Email Verification",
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
                          "A verification code has been sent to ${widget.email}. Please enter the code below to verify your email.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 30),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: InputDecoration(
                            labelText: "Verification Code",
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
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 20),
                        _isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : ElevatedButton(
                          onPressed: _submitCode,
                          child: Text(
                            "Verify",
                            style: TextStyle(
                              fontFamily: 'SF-Pro-Text',
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5AA5B1),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            shadowColor: Colors.black26,
                            elevation: 10,
                          ),
                        ),
                        SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Verification code resent to ${widget.email}",
                                  style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "Resend Code",
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
          ),
        ],
      ),
    );
  }
}
