import 'package:flutter/material.dart';
import 'package:frontend/service/latest_service.dart';
import 'package:frontend/service/searchservice.dart';

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
  final LatestService latestService = LatestService();

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
      final books = await latestService.fetchBooks();
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
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
      backgroundColor: isDarkMode ? Colors.black : Colors.white, 
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white, 
        elevation: 0,
        title: Text(
          'Latest',
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            color: isDarkMode ? Colors.white : Colors.black, 
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.search, color: isDarkMode ? Colors.tealAccent : Color(0xFF5AA5B1)), 
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
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Books",
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black87, 
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
                              ? (isDarkMode ? Colors.tealAccent : Color(0xFF5AA5B1))
                              : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
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
                              ? (isDarkMode ? Colors.tealAccent : Color(0xFF5AA5B1))
                              : (isDarkMode ? Colors.grey[800] : Colors.grey[300]),
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
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.65,
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

    String authors = book['authors'] != null && book['authors'] is List
        ? (book['authors'] as List)
        .map((author) => author['fullName'].toString())
        .join(", ")
        : "Unknown Author";

    String bookLink = book['bookLink'] ?? '';
    if (bookLink.isEmpty) {
      bookLink = 'https://via.placeholder.com/150';
    }
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          color: Theme.of(context).cardColor, 
          border: Border.all(
            color: isDarkMode
                ? Colors.white
                : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.4) 
                  : Colors.black.withOpacity(0.1), 
              blurRadius: 8,
              offset: const Offset(0, 6),
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
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12)),
                    child: Image.network(
                      book['image'] ?? 'https://via.placeholder.com/150',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Theme.of(context).dividerColor, 
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.error, 
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image,
                                    size: 30, color: Colors.grey),
                                Text(
                                  'Image not available',
                                  style: Theme.of(context).textTheme.bodySmall,
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ), 
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'By $authors',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 9,
                    ), 
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book['free'] == true
                        ? 'Free'
                        : '₹ ${book['price'] ?? 'Unknown'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: book['free'] == true
                          ? Colors.green 
                          : Colors.red, 
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...buildRatingStars(rating,
                          size: 14,
                          color: Colors.amber), 
                      const SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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


  List<Widget> buildRatingStars(double rating, {double size = 18, required MaterialColor color}) {
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
  final List<dynamic> displayedBooks;

  CustomSearchDelegate(this.displayedBooks);

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
    final results = displayedBooks
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

    return results.isEmpty
        ? Center(
      child: Text(
        'No results found',
        style: TextStyle(fontSize: 16),
      ),
    )
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final book = results[index];
          return categoryCard(context, book);
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = displayedBooks
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

    return suggestions.isEmpty
        ? Center(
      child: Text(
        'No suggestions',
        style: TextStyle(fontSize: 16),
      ),
    )
        : Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65,
        ),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final book = suggestions[index];
          return categoryCard(context, book);
        },
      ),
    );
  }

  Widget categoryCard(BuildContext context, dynamic book) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark; 

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
        width: 140,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[900] : Colors.white, 
          boxShadow: [
            if (!isDarkMode) 
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
          ],
          border: isDarkMode
              ? Border.all(color: Colors.grey[700]!, width: 1) 
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 120,
                width: double.infinity,
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200], 
                child: FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: Image.network(
                    book['image'] ?? 'https://via.placeholder.com/150',
                    width: 140,
                    height: 105,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDarkMode ? Colors.grey[700] : Colors.grey[300], 
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 25, color: Colors.grey),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  fontFamily: 'SF-Pro-Text',
                                  fontSize: 9,
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
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book['title'] ?? 'Unknown Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isDarkMode ? Colors.white : Colors.black, 
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'By $authors',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 9,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[700], 
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    book['free'] == true
                        ? 'Free'
                        : '₹ ${book['price'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                      book['free'] == true ? Colors.green : (isDarkMode ? Colors.red[300] : Colors.red), 
                    ),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      ...buildRatingStars(rating, size: 13),
                      SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontFamily: 'SF-Pro-Text',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
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


  List<Widget> buildRatingStars(double rating, {double size = 18}) {
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
