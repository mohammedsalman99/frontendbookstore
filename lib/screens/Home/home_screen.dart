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
  Map<String, dynamic>? bestAuthor; 
  List<Map<String, String>> categories = [];
  List<dynamic> readingHistory = [];
  List<dynamic> popularBooks = [];
  bool isLoading = true;
  bool hasError = false;
  bool isReadingHistoryLoading = true;
  List<dynamic> trendingBooks = [];

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

  List<dynamic> topAuthors = [];

  Future<void> fetchBestAuthor() async {
    const String authorsUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/authors/with-book-count';
    try {
      final response = await http.get(Uri.parse(authorsUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> authors = data['authors'];
        authors.sort((a, b) => b['bookCount'].compareTo(a['bookCount']));
        final topAuthorsList = authors.take(5).toList();

        setState(() {
          topAuthors = topAuthorsList; 
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
        List<dynamic> sortedByReadings = List.from(books)
          ..sort((a, b) {
            int readsA = a['numberOfReadings'] ?? 0;
            int readsB = b['numberOfReadings'] ?? 0;
            return readsB.compareTo(readsA);
          });
        List<dynamic> sortedByViews = List.from(books)
          ..sort((a, b) {
            int viewsA = a['numberOfViews'] ?? 0;
            int viewsB = b['numberOfViews'] ?? 0;
            return viewsB.compareTo(viewsA);
          });

        setState(() {
          popularBooks = sortedByReadings.take(10).toList(); 
          trendingBooks = sortedByViews.take(10).toList();  
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

      print('API Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('readingHistory') && data['readingHistory'] is List) {
          setState(() {
            readingHistory = data['readingHistory'];
            isReadingHistoryLoading = false;
          });
        } else {
          print('Error: Invalid or missing readingHistory key');
        }
      } else {
        print('HTTP Error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error fetching reading history: $e');
    } finally {
      setState(() {
        isReadingHistoryLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 45),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).cardColor.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for books, authors...',
                        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF5AA5B1), 
                      ),
                      child: Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Categories"),
          ),
          const SizedBox(height: 12), 
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : hasError
              ? const Center(child: Text('Failed to load categories'))
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
          const SizedBox(height: 40), 

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Reading History"),
          ),
          const SizedBox(height: 12),
          isReadingHistoryLoading
              ? const Center(child: CircularProgressIndicator())
              : readingHistory.isEmpty
              ? const Center(child: Text('No reading history available.'))
              : Container(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: readingHistory.length,
              itemBuilder: (context, index) {
                final historyItem = readingHistory[index];
                final book = historyItem['book'];

                if (book != null) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: readingHistoryCard(
                      book['title'] ?? 'Untitled',
                      book['image'] ?? '',
                      book['_id'] ?? '',
                    ),
                  );
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
          const SizedBox(height: 40),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Popular Books"),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : popularBooks.isEmpty
              ? const Center(child: Text('No popular books found'))
              : Container(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularBooks.length,
              itemBuilder: (context, index) {
                return bookCard(popularBooks[index]);
              },
            ),
          ),
          const SizedBox(height: 40),


          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: sectionHeader("Trending Books"),
          ),
          const SizedBox(height: 12),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : trendingBooks.isEmpty
              ? const Center(child: Text('No trending books found'))
              : Container(
            height: 230,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: trendingBooks.length,
              itemBuilder: (context, index) {
                return bookCard(trendingBooks[index]);
              },
            ),
          ),
          const SizedBox(height: 40),

          buildBestAuthorSection(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }




  Widget buildBestAuthorSection() {
    if (topAuthors.isEmpty) {
      return SizedBox.shrink();
    }

    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Authors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87, 
            ),
          ),
          SizedBox(height: 10),
          Container(
            height: 130,
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
                          authorId: author['_id'],
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: author['profilePicture'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 60,
                              height: 60,
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 70,
                          child: Text(
                            author['fullName'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white70 : Colors.black87, 
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 2,
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
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16, 
          ),
        ),
        const Spacer(),
        Icon(Icons.arrow_forward, color: Theme.of(context).iconTheme.color),
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
              color: Theme.of(context).shadowColor, 
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white, 
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
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: book['image'] ?? 'https://via.placeholder.com/150',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: Colors.grey[300],
                ),
                errorWidget: (context, url, error) => Container(
                  height: 100,
                  color: Colors.grey,
                  child: const Icon(Icons.error),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'By ${book['authors']?.first['fullName'] ?? 'Unknown Author'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book['price'] != null
                        ? '\$${book['price']}'
                        : 'Free', 
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: book['price'] != null ? Colors.red : Colors.green, 
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 14,
                        color: index < rating ? Colors.amber : Colors.grey[300],
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
            image: imageUrl.isNotEmpty
                ? CachedNetworkImageProvider(imageUrl)
                : const AssetImage('assets/icons/placeholder.jpg') as ImageProvider,
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
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                  ],
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


}
