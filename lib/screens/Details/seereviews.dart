import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SeeReviewsPage extends StatefulWidget {
  @override
  _SeeReviewsPageState createState() => _SeeReviewsPageState();
}

class _SeeReviewsPageState extends State<SeeReviewsPage> {
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReviews();
  }

  Future<void> fetchReviews() async {
    final response = await http.get(Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/673e56ff95b3d0d9e9fb9d34/reviews'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reviews = List<Map<String, dynamic>>.from(data['reviews']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load reviews');
    }
  }

  void updateReview(Map<String, dynamic> updatedReview, int index) {
    setState(() {
      reviews[index] = updatedReview;  
    });
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
            : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];

                  final fullName = review['user']['fullName'] ?? 'Anonymous';
                  final profilePicture = review['user']['profilePicture'] ?? '';
                  final createdAt = review['createdAt'] ?? 'Unknown Date';
                  final reviewText = review['review'] ?? 'No review provided.';
                  final rating = review['rating']?.toDouble() ?? 0.0;

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
                                backgroundImage: NetworkImage(profilePicture),
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
                                      createdAt,
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
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _showUpdateReviewDialog(review, index);
                            },
                            child: Text("Update Review"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5AA5B1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < (rating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                    ),
                    color: index < (rating ?? 0) ? Colors.amber : Color(0xFF5AA5B1),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final updatedReview = {
                  'user': review['user'],
                  'createdAt': review['createdAt'],
                  'review': reviewController.text,
                  'rating': rating,
                };
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

  Widget buildRatingStars(double rating) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < rating) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: 18));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: 18));
      }
    }
    return Row(children: stars);
  }
}
