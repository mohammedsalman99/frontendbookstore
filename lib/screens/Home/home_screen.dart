import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, String>> categories = [];
  bool isLoading = true;  // Track loading state
  bool hasError = false;  // Track if there was an error fetching data
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchCategories();  // Fetch categories when the screen is initialized
  }

  // Function to fetch categories from the backend
  Future<void> _fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('https://your-backend-url.com/categories'));

      if (response.statusCode == 200) {
        // If the server returns a 200 OK response, parse the data
        final data = jsonDecode(response.body);
        setState(() {
          categories = List<Map<String, String>>.from(
            data.map((item) => {
              'title': item['title'],
              'imageUrl': item['imageUrl'],
            }),
          );
          isLoading = false;
        });
      } else {
        // If the server returns an error
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF5AA5B1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.settings,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            // Search Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
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
            SizedBox(height: 30),
            // Book Category Section with Arrow Indicator
            Row(
              children: [
                Text(
                  "Category",
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF5AA5B1),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Show loading indicator if the data is still loading
            isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                ? Center(child: Text('Failed to load categories'))
                : Container(
              height: 220, // Adjust height as needed to fit two items per row properly
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: (categories.length / 2).ceil(),
                itemBuilder: (context, index) {
                  int firstIndex = index * 2;
                  int secondIndex = firstIndex + 1;

                  return Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: categoryCard(
                          categories[firstIndex]['title']!,
                          categories[firstIndex]['imageUrl']!,
                        ),
                      ),
                      if (secondIndex < categories.length)
                        Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: categoryCard(
                            categories[secondIndex]['title']!,
                            categories[secondIndex]['imageUrl']!,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build each category card
  Widget categoryCard(String title, String imageUrl) {
    return Container(
      width: 180,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
