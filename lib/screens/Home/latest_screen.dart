import 'package:flutter/material.dart';

class LatestScreen extends StatefulWidget {
  @override
  _LatestScreenState createState() => _LatestScreenState();
}

class _LatestScreenState extends State<LatestScreen> {
  List<Map<String, dynamic>> books = [
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'All The Missing Girls',
      'author': 'Megan Miranda',
      'price': '50',
      'premium': 'Premium',
      'rating': 5.0,  // Rating added here
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Aranika and the Syamantaka Jewel',
      'author': 'Aparajita Bose',
      'price': 'Free',
      'premium': '',
      'rating': 3.5,  // Rating added here
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Fast as the Wind',
      'author': 'Thomas Hardy',
      'price': '50',
      'premium': 'Premium',
      'rating': 4.0,  // Rating added here
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'The Demon Girl',
      'author': 'Bertus Aafjes',
      'price': 'Free',
      'premium': '',
      'rating': 2.5,  // Rating added here
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'The Unwilling',
      'author': 'John Hart',
      'price': '100',
      'premium': '',
      'rating': 4.5,  // Rating added here
    },
    {
      'image': 'https://via.placeholder.com/150',
      'title': 'Himself',
      'author': 'John Hart',
      'price': '50',
      'premium': 'Premium',
      'rating': 3.0,  // Rating added here
    },
  ];

  List<Map<String, dynamic>> displayedBooks = [];
  bool isLoading = false;
  int currentPage = 1;
  int totalPages = 3;

  TextEditingController _searchController = TextEditingController();
  String query = '';
  bool isGridView = true;

  @override
  void initState() {
    super.initState();
    loadMoreBooks();
  }

  void loadMoreBooks() {
    if (isLoading || currentPage > totalPages) return;

    setState(() {
      isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        List<Map<String, dynamic>> newBooks = books;
        displayedBooks.addAll(newBooks);
        currentPage++;
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredBooks = displayedBooks
        .where((book) =>
    book['title']!.toLowerCase().contains(query.toLowerCase()) ||
        book['author']!.toLowerCase().contains(query.toLowerCase()))
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
                  delegate: CustomSearchDelegate(),
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
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
              child: NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is ScrollEndNotification &&
                      scrollNotification.metrics.pixels ==
                          scrollNotification.metrics.maxScrollExtent) {
                    loadMoreBooks();
                  }
                  return false;
                },
                child: isGridView
                    ? GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    return categoryCard(
                      filteredBooks[index]['title']!,
                      filteredBooks[index]['image']!,
                      filteredBooks[index]['price']!,
                      filteredBooks[index]['premium']!,
                      filteredBooks[index]['rating'],  // Pass rating here
                    );
                  },
                )
                    : ListView.builder(
                  itemCount: filteredBooks.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: categoryCard(
                        filteredBooks[index]['title']!,
                        filteredBooks[index]['image']!,
                        filteredBooks[index]['price']!,
                        filteredBooks[index]['premium']!,
                        filteredBooks[index]['rating'],  // Pass rating here
                      ),
                    );
                  },
                ),
              ),
            ),
            if (isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Widget categoryCard(String title, String imageUrl, String price, String premium, double rating) {
    return GestureDetector(
      onTap: () {},
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
              ),
              // Gradient overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Premium tag at the top-left corner
              if (premium.isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      premium,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$$price',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        buildRatingStars(rating), // Display rating stars
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget buildRatingStars(double rating) {
    int fullStars = rating.floor();
    double fractionalStar = rating - fullStars;
    int emptyStars = 5 - fullStars - (fractionalStar > 0.0 ? 1 : 0);

    List<Widget> stars = [];
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber, size: 18));
    }

    if (fractionalStar > 0.0) {
      stars.add(Icon(Icons.star_half, color: Colors.amber, size: 18));
    }

    for (int i = 0; i < emptyStars; i++) {
      stars.add(Icon(Icons.star_border, color: Colors.amber, size: 18));
    }

    return Row(
      children: stars,
    );
  }
}

class CustomSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}
