import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Details/categorydetails.dart';
import '../Details/detailpage.dart';
import '../authors_details/author_info.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? bestAuthor; // Variable to hold the best author details
  List<Map<String, String>> categories = [];
  List<dynamic> readingHistory = [];
  List<dynamic> popularBooks = [];
  bool isLoading = true;
  bool hasError = false;
  bool isReadingHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchReadingHistory();
    fetchBooks();
    fetchBestAuthor();
  }


  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  List<dynamic> topAuthors = []; // List to store the top 5 authors

  Future<void> fetchBestAuthor() async {
    const String authorsUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/authors/with-book-count';
    try {
      final response = await http.get(Uri.parse(authorsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> authors = data['authors'];

        // Sort authors by number of books in descending order
        authors.sort((a, b) => b['numberOfBooks'].compareTo(a['numberOfBooks']));
        // Get the top 5 authors
        final topAuthorsList = authors.take(5).toList();

        setState(() {
          topAuthors = topAuthorsList; // Store the top authors in state
        });
      } else {
        throw Exception('Failed to load authors');
      }
    } catch (e) {
      print('Error fetching top authors: $e');
    }
  }


  Future<void> fetchBooks() async {
    const String booksUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books';
    try {
      final response = await http.get(Uri.parse(booksUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> books = data['books'];

        books.sort((a, b) {
          int viewsA = a['numberOfViews'] ?? 0;
          int viewsB = b['numberOfViews'] ?? 0;
          int readsA = a['numberOfReadings'] ?? 0;
          int readsB = b['numberOfReadings'] ?? 0;
          return (viewsB.compareTo(viewsA) != 0) ? viewsB.compareTo(viewsA) : readsB.compareTo(readsA);
        });

        setState(() {
          popularBooks = books;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/categories'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          categories = List<Map<String, String>>.from(
            data['categories'].map((item) {
              return {
                'title': item['title'].toString(),
                'imageUrl': item['image'].toString(),
                'id': item['_id'].toString(),
              };
            }),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _fetchReadingHistory() async {
    final readingHistoryUrl =
        'https://readme-backend-zdiq.onrender.com/api/v1/reading-history';

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }

      final response = await http.get(
        Uri.parse(readingHistoryUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            readingHistory = data['readingHistory'];
            isReadingHistoryLoading = false;
          });
        } else {
          throw Exception(
              "Failed to fetch reading history: ${data['message']}");
        }
      } else {
        throw Exception(
            "Error: ${response.statusCode} ${response.reasonPhrase}");
      }
    } catch (e) {
      print('Error fetching reading history: $e');
      setState(() {
        isReadingHistoryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          SizedBox(height: 45),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Readme',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          SizedBox(height: 13),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search book here...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Icon(Icons.search, color: Color(0xFF5AA5B1)),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Categories Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Categories"),
          ),
          SizedBox(height: 10),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : hasError
              ? Center(child: Text('Failed to load categories'))
              : Container(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: categoryCard(
                    categories[index]['title']!,
                    categories[index]['imageUrl']!,
                    categories[index]['id']!,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),

          // Reading History Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Reading History"),
          ),
          SizedBox(height: 10),
          isReadingHistoryLoading
              ? Center(child: CircularProgressIndicator())
              : readingHistory.isEmpty
              ? Center(child: Text('No reading history found'))
              : Container(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: readingHistory.length,
              itemBuilder: (context, index) {
                final book = readingHistory[index]['book'];
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: readingHistoryCard(
                    book['title'],
                    book['image'],
                    book['_id'],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),

          // Popular Books Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Popular Books"),
          ),
          SizedBox(height: 10),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : popularBooks.isEmpty
              ? Center(child: Text('No popular books found'))
              : Container(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularBooks.length,
              itemBuilder: (context, index) {
                return bookCard(popularBooks[index]);
              },
            ),
          ),

          // Add Top Authors Section at the Bottom
          buildBestAuthorSection(),
          SizedBox(height: 50),
        ],
      ),
    );
  }



  Widget buildBestAuthorSection() {
    if (topAuthors.isEmpty) {
      return SizedBox.shrink(); // Return an empty widget if no authors are available
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Authors',
            style: TextStyle(
              fontSize: 18, // Suitable size for section title
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 130, // Adjust height for the horizontal list
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: topAuthors.length,
              itemBuilder: (context, index) {
                final author = topAuthors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthorInfoScreen(
                          authorId: author['_id'], // Pass author ID
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0), // Adjust spacing between authors
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: author['profilePicture'],
                            width: 60, // Profile picture size
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8), // Space between image and name
                        Container(
                          width: 70, // Fixed width to prevent overflow
                          child: Text(
                            author['fullName'],
                            style: TextStyle(
                              fontSize: 10, // Reduced font size for names
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2, // Allow names to wrap to two lines
                            textAlign: TextAlign.center,
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
    );
  }


  Widget sectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Spacer(),
        Icon(Icons.arrow_forward, color: Color(0xFF5AA5B1)),
      ],
    );
  }

  Widget categoryCard(String title, String imageUrl, String categoryId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BooksScreen(
              categoryId: categoryId,
              categoryTitle: title,
            ),
          ),
        ).then((_) => _fetchReadingHistory());
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget bookCard(dynamic book) {
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
        width: 160,
        height: 110, // Adjusted height for added rating section
        margin: EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1), // Edge border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 2), // Slight shadow for elevation
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Image
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                height: 100, // Adjusted height for the image
                width: double.infinity,
                child: Image.network(
                  book['image'] ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Book Details
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Title
                  Text(
                    book['title'] ?? 'Unknown Title',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 3),
                  // Author(s)
                  Text(
                    'By ${(book['authors'] as List).map((e) => e['fullName']).join(", ")}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  SizedBox(height: 5),
                  // Rating Section
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 11, // Suitable size for the stars
                        color: index < rating ? Colors.amber : Colors.grey.shade300,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget readingHistoryCard(String title, String imageUrl, String bookId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(bookId: bookId),
          ),
        ).then((_) => _fetchReadingHistory());
      },
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: CachedNetworkImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
