import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Details/categorydetails.dart';
import '../Details/detailpage.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> categories = [];
  List<dynamic> readingHistory = [];
  bool isLoading = true;
  bool hasError = false;
  bool isReadingHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchReadingHistory();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchCategories() async {
    try {
      final response =
      await http.get(Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/categories'));

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
    final readingHistoryUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/reading-history';

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
          throw Exception("Failed to fetch reading history: ${data['message']}");
        }
      } else {
        throw Exception("Error: ${response.statusCode} ${response.reasonPhrase}");
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 45),
              Text(
                'Readme',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 13),

              // Search Box
              Container(
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
              SizedBox(height: 20),

              // Categories Section
              sectionHeader("Categories"),
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
              sectionHeader("Reading History"),
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
            ],
          ),
        ),
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
        );
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

  Widget readingHistoryCard(String title, String imageUrl, String bookId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(bookId: bookId),
          ),
        );
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
