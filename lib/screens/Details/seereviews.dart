import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class SeeReviewsPage extends StatefulWidget {
  final String bookId;

  SeeReviewsPage({required this.bookId});

  @override
  _SeeReviewsPageState createState() => _SeeReviewsPageState();
}

class _SeeReviewsPageState extends State<SeeReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  String? loggedInUserId;

  @override
  void initState() {
    super.initState();
    fetchLoggedInUserId();
    fetchReviews(widget.bookId);
  }

  Future<void> fetchLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    loggedInUserId = prefs.getString('user_id');
    print('Logged-in user ID: $loggedInUserId');
  }

  Future<void> fetchReviews(String bookId) async {
    final url = 'https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/reviews';

    try {
      final response = await http.get(Uri.parse(url));
      print('Raw response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed data: $data');

        if (data['reviews'] != null && data['reviews'] is List) {
          setState(() {
            reviews = List<Map<String, dynamic>>.from(data['reviews']);
            isLoading = false;
          });
          print('Reviews fetched and state updated.');
        } else {
          setState(() {
            reviews = [];
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No reviews found.")),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch reviews: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print('Network error occurred: $e');
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> deleteReview(String bookId, String reviewId) async {
    final url = 'https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/reviews/$reviewId';

    try {
      print('Making DELETE request to: $url');
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        print('Token is missing. User must log in.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication required. Please log in.")),
        );
        return;
      }

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Review deleted successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Review deleted successfully.")),
        );
        setState(() {
          reviews.removeWhere((review) => review['_id'] == reviewId);
        });
      } else {
        print('Failed to delete review: ${response.statusCode} - ${response.reasonPhrase}');
        print('Error Details: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to delete review: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print('Error deleting review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting review: $e")),
      );
    }
  }



  Future<void> updateReviewOnServer(String bookId, String reviewId, Map<String, dynamic> updatedReview) async {
    final url = 'https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/reviews/$reviewId';

    try {
      print('Making PUT request to: $url');
      print('Request Body: ${jsonEncode(updatedReview)}');
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        print('Token is missing. User must log in.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Authentication required. Please log in.")),
        );
        return;
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updatedReview),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('Review updated successfully.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Review updated successfully.")),
        );
      } else {
        print('Failed to update review: ${response.statusCode} - ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update review: ${response.reasonPhrase}")),
        );
      }
    } catch (e) {
      print('Error updating review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating review: $e")),
      );
    }
  }



  void updateReview(Map<String, dynamic> updatedReview, int index) {
    setState(() {
      reviews[index] = {
        ...reviews[index],
        ...updatedReview,
      };
    });
  }

  void _showUpdateReviewDialog(Map<String, dynamic> review, int index) {
    TextEditingController reviewController = TextEditingController(text: review['review']);
    double? rating = review['rating']?.toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Review"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reviewController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Edit your review...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < (rating ?? 0) ? Icons.star : Icons.star_border,
                    ),
                    color: i < (rating ?? 0) ? Colors.amber : Color(0xFF5AA5B1),
                    onPressed: () {
                      setState(() {
                        rating = i + 1.0;
                      });
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                final updatedReview = {
                  'review': reviewController.text,
                  'rating': rating?.toInt(),
                };
                await updateReviewOnServer(widget.bookId, review['_id'], updatedReview);
                updateReview(updatedReview, index);
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("See Reviews"),
        backgroundColor: Color(0xFF5AA5B1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            final fullName = review['user']['fullName'] ?? 'Anonymous';
            final profilePicture = review['user']['profilePicture'] ?? '';
            final createdAt = review['createdAt'] ?? 'Unknown Date';
            final reviewText = review['review'] ?? 'No review provided.';
            final rating = review['rating']?.toDouble() ?? 0.0;
            final formattedDate = DateFormat('MMM d, yyyy').format(DateTime.parse(createdAt));
            final isAuthor = loggedInUserId == review['user']['_id'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            profilePicture.isNotEmpty
                                ? profilePicture
                                : 'https://via.placeholder.com/150',
                          ),
                          radius: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        buildRatingStars(rating),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      reviewText,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    if (isAuthor) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              _showUpdateReviewDialog(review, index);
                            },
                            child: Text("Update"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5AA5B1),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              deleteReview(widget.bookId, review['_id']);
                            },
                            child: Text("Delete"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildRatingStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }
}
