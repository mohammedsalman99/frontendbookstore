import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WriteReviewPage extends StatefulWidget {
  final Function(List<Map<String, dynamic>>) updateReviewList;

  WriteReviewPage({required this.updateReviewList}); // Passing update function

  @override
  _WriteReviewPageState createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int _selectedRating = 0;
  TextEditingController _reviewController = TextEditingController(); // To capture review text

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Write a Review"),
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
            Text(
              "Write Your Review",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5AA5B1),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 5,
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
                    fontSize: 18,
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
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5AA5B1),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
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

  Future<void> _submitReview() async {
    if (_selectedRating == 0 || _reviewController.text.isEmpty) {
      // Handle case where rating or review is empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please provide both a rating and a review."),
      ));
      return;
    }

    // Prepare the data to send
    final reviewData = {
      'rating': _selectedRating,
      'review': _reviewController.text,
    };

    // Retrieve the token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token'); // Retrieve the token

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("You need to log in first."),
      ));
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/673e56ff95b3d0d9e9fb9d34/reviews'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Add the token to the request headers
        },
        body: jsonEncode(reviewData),
      );

      // Log the response body for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Successfully submitted the review
        final data = jsonDecode(response.body);
        final newReview = {
          'rating': data['review']['rating'],
          'review': data['review']['review'],
          'user': data['review']['user'],
        };

        // Update the parent widget's review list with the new review
        widget.updateReviewList([newReview]); // Update review list in the parent widget

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Review submitted successfully!"),
          backgroundColor: Colors.green,
        ));

        Navigator.pop(context); // Close the page
      } else {
        // Handle failure response
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to submit the review. Please try again."),
        ));
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error occurred: $e"),
      ));
    }
  }
}
