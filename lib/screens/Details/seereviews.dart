import 'package:flutter/material.dart';

class SeeReviewsPage extends StatelessWidget {
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'John Doe',
      'avatar': 'https://via.placeholder.com/50',
      'rating': 5.0,
      'review': 'Amazing book! Couldn\'t put it down.',
      'date': 'Nov 20, 2024',
    },
    {
      'name': 'Jane Smith',
      'avatar': 'https://via.placeholder.com/50',
      'rating': 4.0,
      'review': 'Great read, but some parts were slow.',
      'date': 'Nov 18, 2024',
    },
    {
      'name': 'Mark Johnson',
      'avatar': 'https://via.placeholder.com/50',
      'rating': 3.0,
      'review': 'It was okay. The story was predictable.',
      'date': 'Nov 15, 2024',
    },
    {
      'name': 'Emily Davis',
      'avatar': 'https://via.placeholder.com/50',
      'rating': 4.5,
      'review': 'Loved the characters and plot twists!',
      'date': 'Nov 10, 2024',
    },
    {
      'name': 'Chris Lee',
      'avatar': 'https://via.placeholder.com/50',
      'rating': 2.5,
      'review': 'Not my cup of tea. Found it quite boring.',
      'date': 'Nov 5, 2024',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("See Reviews"),
        backgroundColor: Color(0xFF5AA5B1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              print("Filter reviews clicked!");
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
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
                          backgroundImage: NetworkImage(review['avatar']),
                          radius: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                review['date'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        buildRatingStars(review['rating']),
                      ],
                    ),
                    SizedBox(height: 12),

                    Text(
                      review['review'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
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
