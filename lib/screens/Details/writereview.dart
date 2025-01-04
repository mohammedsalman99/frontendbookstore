import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WriteReviewPage extends StatefulWidget {
  final String bookId;
  final Function() refreshBookDetails;

  WriteReviewPage({
    required this.bookId,
    required this.refreshBookDetails,
  });

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int _selectedRating = 0;
  TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _reviewController.text.isEmpty) {
      _showAdvancedDialog(
        title: "Missing Input",
        message: "Please provide both a rating and a review.",
        backgroundColor: Colors.white,
        icon: Icons.warning_amber_outlined,
        iconColor: Colors.orange,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final reviewData = {
      'rating': _selectedRating,
      'review': _reviewController.text,
    };

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showAdvancedDialog(
        title: "Not Logged In",
        message: "You need to log in before submitting a review.",
        backgroundColor: Colors.white,
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 201) {
        _showAdvancedDialog(
          title: "Review Submitted",
          message: "Thank you for your review! It has been submitted successfully.",
          backgroundColor: Color(0xFFE8F5E9),
          icon: Icons.check_circle_outline,
          iconColor: Colors.green,
        );

        widget.refreshBookDetails();
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pop(context); 
        });
      } else if (response.statusCode == 400) {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? "Your review contains inappropriate content.";
        final isDuplicate = errorMessage.contains("duplicate");

        if (isDuplicate) {
          _showAdvancedDialog(
            title: "Duplicate Review",
            message: "You have already submitted a review for this book.",
            backgroundColor: Colors.amber.shade50,
            icon: Icons.copy,
            iconColor: Colors.amber,
          );
        } else {
          final suggestion = responseBody['suggestion'] ?? "Please revise your review to remove any offensive language.";
          _showAdvancedDialog(
            title: "Inappropriate Content",
            message: errorMessage,
            backgroundColor: Colors.white,
            icon: Icons.block,
            iconColor: Colors.red,
            suggestion: suggestion,
          );
        }
      } else {
        _showAdvancedDialog(
          title: "Submission Failed",
          message: "An unexpected error occurred. Please try again later.",
          backgroundColor: Colors.white,
          icon: Icons.error_outline,
          iconColor: Colors.red,
        );
      }
    } catch (e) {
      _showAdvancedDialog(
        title: "Error",
        message: "An error occurred while submitting your review: $e",
        backgroundColor: Colors.white,
        icon: Icons.error_outline,
        iconColor: Colors.red,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAdvancedDialog({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    String? suggestion,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: iconColor,
                    size: 70,
                  ),
                  SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  if (suggestion != null) ...[
                    SizedBox(height: 10),
                    Divider(color: Colors.black26),
                    SizedBox(height: 10),
                    Text(
                      "Suggestion:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    Text(
                      suggestion,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); 
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("OK"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Write a Review",
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'SF-Pro-Text',
            fontSize: 18,
          ),
        ),
        backgroundColor: Color(0xFF5AA5B1),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 11),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              maxLength: 250,
              decoration: InputDecoration(
                hintText: "Write your review here...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Rate the Book:",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        size: 18,
                      ),
                      color: index < _selectedRating
                          ? Colors.amber
                          : Color(0xFF5AA5B1),
                      onPressed: () {
                        setState(() {
                          _selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSubmitting ? Colors.grey : Color(0xFF5AA5B1),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "SUBMIT REVIEW",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
