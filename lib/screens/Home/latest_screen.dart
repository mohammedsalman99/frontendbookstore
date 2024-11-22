import 'package:flutter/material.dart';
import 'package:frontend/service/latest_service.dart';
import '../Details/detailpage.dart';

class LatestScreen extends StatefulWidget {
  @override
  _LatestScreenState createState() => _LatestScreenState();
}

class _LatestScreenState extends State<LatestScreen> {
  List<dynamic> displayedBooks = [];
  bool isFetching = true;
  String query = '';
  bool isGridView = true;
  final LatestService latestService = LatestService(); // Create a service instance

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    setState(() {
      isFetching = true;
    });

    try {
      final books = await latestService.fetchBooks(); // Use the service method
      setState(() {
        displayedBooks = books;
      });
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    List<dynamic> filteredBooks = displayedBooks
        .where((book) =>
    book['title']
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        book['author']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Latest',
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.search, color: Color(0xFF5AA5B1)),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(displayedBooks),
                );
              },
            ),
          ),
        ],
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Books",
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isGridView = true;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isGridView
                              ? Color(0xFF5AA5B1)
                              : Colors.grey[300],
                        ),
                        child: Icon(Icons.grid_on, color: Colors.white),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isGridView = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !isGridView
                              ? Color(0xFF5AA5B1)
                              : Colors.grey[300],
                        ),
                        child: Icon(Icons.list, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two cards per row
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65, // More height for each card
                ),
                itemCount: filteredBooks.length,
                itemBuilder: (context, index) {
                  return categoryCard(filteredBooks[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget categoryCard(dynamic book) {
    double rating = book['rating'] != null
        ? double.tryParse(book['rating'].toString()) ?? 0.0
        : 0.0;

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
            // Image with Gradient Overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9, // Ensures proportional image display
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
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
                                    size: 40, color: Colors.grey),
                                Text(
                                  'Image not available',
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontSize: 12,
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
            // Content Section
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    book['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Author
                  Text(
                    'By ${book['author'] ?? 'Unknown'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Price
                  Text(
                    book['free'] == true
                        ? 'Free'
                        : '₹ ${book['price'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: book['free'] == true ? Colors.green : Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Rating
                  Row(
                    children: [
                      ...buildRatingStars(rating, size: 14), // Smaller star size
                      SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontFamily: 'SF-Pro-Text',
                          fontSize: 20,
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

  List<Widget> buildRatingStars(double rating, {double size = 25}) {
    List<Widget> stars = [];
    for (int i = 0; i < 5; i++) {
      if (i < rating) {
        stars.add(Icon(Icons.star, color: Colors.amber, size: size));
      } else {
        stars.add(Icon(Icons.star_border, color: Colors.amber, size: size));
      }
    }
    return stars;
  }
}




class CustomSearchDelegate extends SearchDelegate<String> {
  final List<dynamic> books;

  CustomSearchDelegate(this.books);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = books
        .where((book) =>
    book['title']
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        book['author']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return ListTile(
          title: Text(book['title']),
          subtitle: Text('By ${book['author']}'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(bookId: book['_id']),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = books
        .where((book) =>
    book['title']
        .toString()
        .toLowerCase()
        .contains(query.toLowerCase()) ||
        book['author']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final book = suggestions[index];
        return ListTile(
          title: Text(book['title']),
          subtitle: Text('By ${book['author']}'),
          onTap: () {
            query = book['title'];
            showResults(context);
          },
        );
      },
    );
  }
}
