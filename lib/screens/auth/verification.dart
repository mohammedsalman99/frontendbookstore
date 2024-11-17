import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VerificationPage extends StatefulWidget {
  final String email;

  VerificationPage({required this.email});

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
        Uri.parse('https://your-backend-host.com/users/verify_email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email,
          'code': code,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Invalid verification code';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error,
              style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred. Please try again.",
            style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
          ),
        ),
      );
      return false;
    }
  }

  void _submitCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please enter the verification code",
            style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
          ),
        ),
      );
      return;
    }

    bool isValid = await _verifyCode(_codeController.text);

    if (isValid) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Invalid verification code",
            style: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Email Verification",
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.w600, // SemiBold
            color: Color(0xFF5AA5B1),
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF5AA5B1)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.mail_outline,
              size: 100,
              color: Color(0xFF5AA5B1),
            ),
            SizedBox(height: 20),
            Text(
              "A verification code has been sent to ${widget.email}. Please enter the code below to verify your email.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'SF-Pro-Text',
                fontSize: 16,
                fontWeight: FontWeight.w400, // Regular
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Verification Code",
                labelStyle: TextStyle(fontFamily: 'SF-Pro-Text', fontWeight: FontWeight.w400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.lock, color: Color(0xFF5AA5B1)),
              ),
            ),
            SizedBox(height: 20),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submitCode,
              child: Text(
                "Verify",
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5AA5B1),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
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
                  fontWeight: FontWeight.w500, // Medium
                  color: Color(0xFF5AA5B1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
