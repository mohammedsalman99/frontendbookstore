import 'package:flutter/material.dart';

class VerificationPage extends StatefulWidget {
  final String email;

  VerificationPage({required this.email});

  @override
  _VerificationPageState createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  // Simulated function to verify the code (replace with actual backend call)
  Future<bool> _verifyCode(String code) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a delay for verification (you would replace this with an API call)
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    // For demonstration, let's assume the correct code is "123456"
    return code == "123456";
  }

  void _submitCode() async {
    if (_codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter the verification code")),
      );
      return;
    }

    bool isValid = await _verifyCode(_codeController.text);

    if (isValid) {
      // Navigate to the home screen or another protected page upon successful verification
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid verification code")),
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
          style: TextStyle(color: Color(0xFF5AA5B1)),
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
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: "Verification Code",
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
              child: Text("Verify"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5AA5B1), // Same color as Sign Up button
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                // Simulate resending verification code logic (replace with actual backend call)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Verification code resent to ${widget.email}")),
                );
              },
              child: Text(
                "Resend Code",
                style: TextStyle(color: Color(0xFF5AA5B1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
