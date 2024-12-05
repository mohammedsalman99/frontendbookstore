import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detailpage.dart'; 

class BooksScreen extends StatefulWidget {
  final String categoryId;
  final String categoryTitle;

  BooksScreen({required this.categoryId, required this.categoryTitle});

  @override
  _BooksScreenState createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  List<dynamic> books = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    final apiUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books';

    try {
      print('Fetching books from API: $apiUrl');
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        print('Response received. Parsing JSON...');
        try {
          final data = jsonDecode(response.body);
          print('Raw response data: $data');
          if (data['books'] != null && data['books'] is List) {
            print('Filtering books by category...');
            final filteredBooks = data['books'].where((book) {
              return book['category']['_id'] == widget.categoryId;
            }).toList();

            setState(() {
              books = filteredBooks;
              isLoading = false;
            });
            print('Books successfully filtered and state updated.');
          } else {
            print('No books field or books is not a list.');
            setState(() {
              hasError = true;
              isLoading = false;
            });
          }
        } catch (jsonError) {
          print('Error decoding JSON response: $jsonError');
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (networkError) {
      print('Network error occurred: $networkError');
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryTitle),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
          ? Center(child: Text('Failed to load books'))
          : books.isEmpty
          ? Center(child: Text('No books found for this category.'))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.7,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return buildBookCard(context, book);
          },
        ),
      ),
    );
  }

  Widget buildBookCard(BuildContext context, dynamic book) {
    double rating = book['rating'] != null
        ? double.tryParse(book['rating'].toString()) ?? 0.0
        : 0.0;

    String authors = book['authors'] != null && book['authors'] is List
        ? (book['authors'] as List)
        .map((author) => author['fullName'].toString())
        .join(", ")
        : "Unknown Author";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(bookId: book['_id']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      book['image'] ?? 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image,
                                    size: 30, color: Colors.grey),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'By $authors',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 9,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    book['free'] == true
                        ? 'Free'
                        : '₹ ${book['price'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: book['free'] == true ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      ...buildRatingStars(rating, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontFamily: 'SF-Pro-Text',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildRatingStars(double rating, {double size = 20}) {
    int fullStars = rating.floor();
    bool hasHalfStar = rating - fullStars >= 0.5;

    List<Widget> stars = List.generate(fullStars, (index) {
      return Icon(Icons.star, size: size, color: Colors.amber);
    });

    if (hasHalfStar) {
      stars.add(Icon(Icons.star_half, size: size, color: Colors.amber));
    }

    int remainingStars = 5 - stars.length;
    stars.addAll(
      List.generate(remainingStars, (index) {
        return Icon(Icons.star_border, size: size, color: Colors.amber);
      }),
    );

    return stars;
  }
}
