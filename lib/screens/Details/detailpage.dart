import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'report.dart';
import 'writereview.dart';
import 'seereviews.dart';
import 'pdf_viewer_page.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../payment/subscription.dart';
import '../payment/Purchasebook.dart';


class DetailPage extends StatefulWidget {
  final String bookId;

  const DetailPage({Key? key, required this.bookId}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool isLoading = true;
  Map<String, dynamic>? bookData;
  bool isFavorited = false;


  @override
  void initState() {
    super.initState();
    loadFavoriteState();
    fetchBookDetails();
  }

  Future<bool> checkUserAccess(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      print("Authentication token is null.");
      _showAdvancedMessage(
        "Authentication Error",
        "Please log in to verify access.",
        isError: true,
      );
      // Redirect to login
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }

    try {
      // First API Call: Check purchase status
      final purchaseResponse = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/purchase-status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (purchaseResponse.statusCode == 200) {
        final purchaseData = json.decode(purchaseResponse.body);
        print("Purchase Data: $purchaseData");

        if (purchaseData['isPurchased'] == true || purchaseData['isFree'] == true) {
          print("Access granted via purchase or free status.");
          return true;
        }

        if (purchaseData['requiresSubscription'] == true) {
          return await checkSubscriptionStatus();
        }

        _showAdvancedMessage(
          "Purchase Required",
          "You need to purchase this book or have an active subscription.",
          isError: true,
        );
        return false;
      } else if (purchaseResponse.statusCode == 401) {
        // Handle expired token
        _showAdvancedMessage(
          "Authentication Error",
          "Your session has expired. Please log in again.",
          isError: true,
        );
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      } else {
        throw Exception("Unexpected status code: ${purchaseResponse.statusCode}");
      }
    } catch (e) {
      print("Error in checkUserAccess: $e");
      _showAdvancedMessage(
        "Error",
        "An error occurred while verifying access. Please try again later.",
        isError: true,
      );
      return false;
    }
  }



  Future<void> loadFavoriteState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isFavorited = prefs.getBool('favorite_${widget.bookId}') ?? false;
    });
  }
  Future<void> toggleFavorite() async {
    final toggleFavoriteUrl =
        'https://readme-backend-zdiq.onrender.com/api/v1/favorites/books/${widget.bookId}';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showAdvancedMessage(
          "Authentication Error",
          "Please log in to toggle favorites.",
          isError: true,
        );
        return;
      }

      final response = await http.post(
        Uri.parse(toggleFavoriteUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          isFavorited = data['isFavorited'];
        });

        await prefs.setBool('favorite_${widget.bookId}', isFavorited);

        _showAdvancedMessage(
          "Success",
          data['message'] ?? "Favorite toggled successfully.",
          isError: false,
        );
      } else {
        _showAdvancedMessage(
          "Error",
          "Failed to toggle favorite. Please try again later.",
          isError: true,
        );
      }
    } catch (e) {
      _showAdvancedMessage(
        "Error",
        "An error occurred: $e",
        isError: true,
      );
    }
  }



  Future<void> incrementReadingHistory() async {
    final readingHistoryUrl =
        'https://readme-backend-zdiq.onrender.com/api/v1/reading-history//books/${widget.bookId}';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Authentication token is missing. Please log in again.");
      }
      final response = await http.post(
        Uri.parse(readingHistoryUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Reading history updated successfully!")),
          );
        } else {
          throw Exception("Failed to update reading history: ${data['message'] ?? 'Unknown error'}");
        }
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.reasonPhrase}");
      }
    } catch (e) {
      print('Error during reading history update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating reading history: $e")),
      );
    }
  }


  Future<void> incrementDownload() async {
    final downloadUrl =
        'https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/download';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showAdvancedMessage(
          "Authentication Error",
          "Please log in to download this book.",
          isError: true,
        );
        return;
      }

      final response = await http.post(
        Uri.parse(downloadUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var box = Hive.box('downloads');
        Map<String, dynamic> bookDetails = {
          'id': bookData!['_id'],
          'title': bookData!['title'],
          'image': bookData!['image'],
          'bookLink': bookData!['bookLink'],
        };

        final existingBooks = box.values.where((element) {
          final map = Map<String, dynamic>.from(element);
          return map['id'] == bookDetails['id'];
        });

        if (existingBooks.isEmpty) {
          box.add(bookDetails);
        }

        _showAdvancedMessage(
          "Download Started",
          "Your download has started successfully.",
          isError: false,
        );
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        _showAdvancedMessage(
          "Access Denied",
          data['message'] ?? "You need an active subscription to download this book.",
          isError: true,
        );
      } else {
        _showAdvancedMessage(
          "Error",
          "Failed to start download. Status: ${response.statusCode}. ${response.reasonPhrase}",
          isError: true,
        );
      }
    } catch (e) {
      print("Exception during download: $e");
      _showAdvancedMessage(
        "Error",
        "An error occurred: $e",
        isError: true,
      );
    }
  }


  Future<bool> checkPurchaseStatus(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showAdvancedMessage(
        "Authentication Error",
        "Please log in to proceed.",
        isError: true,
      );
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/purchase-status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['isPurchased'] == true || data['isFree'] == true) {
          return true;
        }

        if (data['requiresSubscription'] == true && data['hasSubscriptionAccess'] == false) {
          return await checkSubscriptionStatus();
        }

        _showAdvancedMessage(
          "Purchase Required",
          "You need to purchase this book or have an active subscription.",
          isError: true,
        );
        return false;
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showAdvancedMessage(
        "Error",
        "Failed to check purchase status. Please try again.",
        isError: true,
      );
      return false;
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showAdvancedMessage(
        "Authentication Error",
        "Please log in to check your subscription status.",
        isError: true,
      );
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/subscription/details'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['subscription']['status'] == 'active') {
          return true;
        } else {
          _showAdvancedMessage(
            "Subscription Required",
            "Your subscription is inactive or expired. Please renew to access premium books.",
            isError: true,
          );
          return false;
        }
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      _showAdvancedMessage(
        "Error",
        "Failed to check subscription status. Please try again.",
        isError: true,
      );
      return false;
    }
  }



  void _showAdvancedMessage(String title, String message, {required bool isError}) {
    final backgroundColor = isError ? Colors.red.shade100 : Colors.green.shade100;
    final icon = isError ? Icons.error : Icons.check_circle;
    final iconColor = isError ? Colors.red : Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 8.0,
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 4),
      ),
    );
  }



  Future<void> incrementView() async {
    final viewUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/view';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception("Authentication token is missing. Please log in again.");
      }
      final response = await http.post(
        Uri.parse(viewUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('numberOfViews') && data['numberOfViews'] != null) {
          setState(() {
            bookData!['numberOfViews'] = data['numberOfViews'];
          });
        } else {
          throw Exception("Response missing 'numberOfViews' key");
        }
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.reasonPhrase}");
      }
    } catch (e) {
      print('Error during view increment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating views: $e")),
      );
    }
  }


  Future<void> incrementReading() async {
    final readingUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/read';

    try {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        _showAdvancedMessage(
          "Authentication Error",
          "Please log in to access this book.",
          isError: true,
        );
        return;
      }

      final response = await http.post(
        Uri.parse(readingUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showAdvancedMessage(
            "Access Granted",
            "You can now read this book.",
            isError: false,
          );
        } else if (data.containsKey('message')) {
          _showAdvancedMessage(
            "Subscription Required",
            data['message'],
            isError: true,
          );
        } else {
          _showAdvancedMessage(
            "Unknown Error",
            "Unable to process your request. Please try again.",
            isError: true,
          );
        }
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        _showAdvancedMessage(
          "Access Denied",
          data['message'] ?? "This book requires an active subscription.",
          isError: true,
        );
      } else {
        _showAdvancedMessage(
          "Server Error",
          "Unable to process your request. Please try again later.",
          isError: true,
        );
      }
    } catch (e) {
      print('Error during reading increment: $e');
      _showAdvancedMessage(
        "Network Error",
        "An error occurred. Please check your internet connection and try again.",
        isError: true,
      );
    }
  }

  Future<void> fetchBookDetails() async {
    try {
      // Make the API request to fetch book details
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}'),
      );

      print("FetchBookDetails API Response: ${response.statusCode}");
      print("FetchBookDetails Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if 'book' key exists in the response
        if (data.containsKey('book')) {
          setState(() {
            bookData = data['book'];

            // Validate and handle the book link
            if (bookData != null && bookData!['bookLink'] != null && bookData!['bookLink'].isNotEmpty) {
              String pdfUrl = bookData!['bookLink'];

              // Handle Google Drive links
              final uri = Uri.parse(pdfUrl);
              if (uri.host.contains('drive.google.com') && uri.queryParameters.containsKey('id')) {
                bookData!['bookLink'] =
                'https://drive.google.com/uc?export=download&id=${uri.queryParameters['id']}';
                print("Formatted Google Drive link: ${bookData!['bookLink']}");
              } else {
                print("Book link is a direct link: $pdfUrl");
              }
            } else {
              print("Error: Book link is null or empty.");
              bookData!['bookLink'] = null; // Ensure it is explicitly null for handling later
            }

            isLoading = false; // Stop loading indicator
          });
        } else {
          throw Exception("Invalid response: 'book' key missing");
        }
      } else {
        // Log and throw an exception for non-200 status codes
        throw Exception("Error: ${response.statusCode}, ${response.reasonPhrase}");
      }
    } catch (e) {
      // Catch any error and display a message to the user
      print("Error in fetchBookDetails: $e");

      setState(() {
        isLoading = false; // Stop loading indicator
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching book details: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void updateReviewList(List<Map<String, dynamic>> newReviews) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Detail Page",
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'SF-Pro-Text',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF5AA5B1),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (bookData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Detail Page",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Color(0xFF5AA5B1),
        ),
        body: Center(child: Text("Failed to load book details.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Page",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF5AA5B1),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: Colors.white,
            ),
            onPressed: () async {
              await toggleFavorite();
              setState(() {});
            },
            tooltip: isFavorited ? "Remove from Favorites" : "Add to Favorites",
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () async {
              final sharableLink = "https://Readme.com/detail?bookId=${widget.bookId}";
              await Clipboard.setData(ClipboardData(text: sharableLink));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Link copied to clipboard")),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      bookData!['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                    ),
                  ),
                  if (!bookData!['free'])
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
                          "Premium",
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookData!['title'],
                      style: TextStyle(
                        fontFamily: 'SF-Pro-Text',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 7),
                    RichText(
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: 'By ',
                            style: TextStyle(
                              fontFamily: 'SF-Pro-Text',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          ...?bookData!['authors']?.map<TextSpan>((author) {
                            return TextSpan(
                              text: '${author['fullName']}, ',
                              style: const TextStyle(
                                fontFamily: 'SF-Pro-Text',
                                fontSize: 12,
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          bookData!['free'] ? "Free" : '₹ ${bookData!['price']}',
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  "${bookData!['numberOfViews']}",
                                  style: TextStyle(
                                    fontFamily: 'SF-Pro-Text',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildActionButton(
                    bookData!['isFavorited'] == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    "Favorite",
                        () async {
                      await toggleFavorite();
                    },
                  ),
                  buildActionButton(Icons.download, "Download", () async {
                    if (!bookData!['free']) {
                      final hasAccess = await checkUserAccess(bookData!['_id']);
                      if (!hasAccess) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubscriptionPage(),
                          ),
                        );
                        return;
                      }
                    }

                    try {
                      await incrementDownload();
                      _showAdvancedMessage(
                        "Download Successful",
                        "Your book has been added to downloads.",
                        isError: false,
                      );
                    } catch (e) {
                      _showAdvancedMessage(
                        "Error",
                        "Failed to download the book. Please try again later.",
                        isError: true,
                      );
                    }
                  }),

                  buildActionButton(Icons.book, "Read", () async {
                    bool hasAccess = await checkUserAccess(bookData!['_id']);

                    if (!hasAccess) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionPage(),
                        ),
                      );
                      return;
                    }

                    if (bookData!['bookLink'] == null || bookData!['bookLink']!.isEmpty) {
                      _showAdvancedMessage(
                        "Error",
                        "The book link is unavailable. Please contact support.",
                        isError: true,
                      );
                      return;
                    }

                    try {
                      await incrementView();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PDFViewerPage(pdfUrl: bookData!['bookLink']),
                        ),
                      );
                    } catch (e) {
                      _showAdvancedMessage(
                        "Error",
                        "An error occurred while opening the book. Please try again.",
                        isError: true,
                      );
                    }
                  }),




                  buildActionButton(Icons.report, "Report", () async {
                    final prefs = await SharedPreferences.getInstance();
                    String? token = prefs.getString('auth_token');

                    if (token == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Authentication token is missing. Please log in again."),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (bookData != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportPage(
                            bookId: bookData!['_id'],
                            bookTitle: bookData!['title'],
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Book details are missing."),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }),


                ],
              ),
              SizedBox(height: 20),

              Text(
                "About this book",
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 7),
              Text(
                bookData!['description'] ?? "No description available.",
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 19),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ratings & Reviews",
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward, color: Color(0xFF5AA5B1)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeeReviewsPage(bookId: widget.bookId),
                        ),
                      );
                    },


                  ),
                ],
              ),
              SizedBox(height: 7),
              Row(
                children: [
                  buildRatingStars(bookData!['rating'].toDouble()),
                  SizedBox(width: 8),
                  Text(
                    "${bookData!['rating']} (${bookData!['numberOfFavourites']} Favourites)",
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 9),
              ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteReviewPage(
                        bookId: widget.bookId,
                        refreshBookDetails: fetchBookDetails,
                      ),
                    ),
                  );
                  fetchBookDetails();
                },
                child: Text(
                  "Write a Review",
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5AA5B1),
                  foregroundColor: Colors.white,
                ),
              ),

              SizedBox(height: 19),

              SizedBox(
                width: double.infinity,
                child: bookData!['free']
                    ? SizedBox.shrink()
                    : ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    String? token = prefs.getString('auth_token');

                    if (token == null) {
                      _showAdvancedMessage(
                        "Authentication Error",
                        "Please log in to purchase this book.",
                        isError: true,
                      );
                      return;
                    }

                    final hasAccess = await checkUserAccess(bookData!['_id']);
                    if (hasAccess) {
                      _showAdvancedMessage(
                        "Access Granted",
                        "You already own this book or have access through a subscription.",
                        isError: false,
                      );
                    } else {
                      final double price = (bookData!['price'] as num).toDouble();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseBookPage(
                            bookId: bookData!['_id'],
                            amount: price,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "BUY BOOK",
                    style: TextStyle(
                      fontFamily: 'SF-Pro-Text',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              )

            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Color(0xFF5AA5B1)),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'SF-Pro-Text',
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
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
