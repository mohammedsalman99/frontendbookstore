
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/screens/Details/summary.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'listen.dart';
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

  Future<void> requestSummary(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showAdvancedMessage(
        "Authentication Error",
        "Please log in to request a summary.",
        isError: true,
      );
      return;
    }

    final url = 'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/$bookId/summary';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _showAdvancedMessage(
          "Summary Requested",
          data['message'],
          isError: false,
        );
      } else {
        _showAdvancedMessage(
          "Error",
          "Failed to request summary. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      _showAdvancedMessage(
        "Network Error",
        "An error occurred. Please check your connection and try again.",
        isError: true,
      );
    }
  }

  Future<String> getSummaryStatus(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      return "Authentication token is missing. Please log in.";
    }

    final url = 'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/$bookId/summary';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'];
      } else {
        return "Failed to fetch summary status. Status: ${response.statusCode}";
      }
    } catch (e) {
      return "Error occurred: $e";
    }
  }



  Future<bool> checkUserAccess(String bookId, {bool refreshDetails = false}) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/purchase-status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['isPurchased'] == true || data['isFree'] == true) {
          if (refreshDetails) {
            await fetchBookDetails();
          }
          return true;
        }

        if (data['hasSubscriptionAccess'] == true) {
          if (refreshDetails) {
            await fetchSubscriptionBookLink(bookId, token);
          }
          return true;
        }

        if (data['hasSubscriptionAccess'] == false) {
          final subscriptionActive = await checkSubscriptionStatus();
          if (subscriptionActive) {
            return true;
          }
        }

        return false;
      } else if (response.statusCode == 401) {
        Navigator.pushReplacementNamed(context, '/login');
        return false;
      } else {
        throw Exception("Unexpected status code: \${response.statusCode}");
      }
    } catch (e) {
      return false;
    }
  }



  Future<void> fetchSubscriptionBookLink(String bookId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/$bookId/protected'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('book') && data['book']['bookLink'] != null) {
          setState(() {
            bookData!['bookLink'] = data['book']['bookLink'];
          });
        }
      }
    } catch (e) {
      // Handle exception if needed
    }
  }


  Future<void> fetchPurchasedBookLink(String bookId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/purchased'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final purchasedBook = data['purchases']?.firstWhere(
                (purchase) => purchase['book']['_id'] == bookId,
            orElse: () => null);

        if (purchasedBook != null && purchasedBook['book']['bookLink'] != null) {
          setState(() {
            bookData!['bookLink'] = purchasedBook['book']['bookLink'];
          });
        }
      }
    } catch (e) {
      // Handle exception if needed
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
        'https://readme-backend-zdiq.onrender.com/api/v1/reading-history/books/${widget.bookId}';

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

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        if (data.containsKey('readingHistory')) {
          // Successfully updated reading history
        } else {
          throw Exception("Unexpected response structure: ${response.body}");
        }
      } else {
        throw Exception("Error: ${response.statusCode}, ${response.reasonPhrase}");
      }
    } catch (e) {
      // Handle exception if needed
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

        return false;
      } else {
        throw Exception("Error: ${response.statusCode}");
      }
    } catch (e) {
      return false;
    }
  }


  Future<bool> checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/subscriptions/details'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['subscription']['status'] == 'active') {
          return true;
        } else {
          return false;
        }
      } else if (response.statusCode == 401) {
        return false;
      } else {
        return false;
      }
    } catch (e) {
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
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception("Please log in to view book details.");
      }

      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/protected'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('book')) {
          bookData = data['book'];

          final hasAccess = data['hasAccess'] ?? false;

          if (hasAccess) {
            if (bookData!['bookLink'] == null || bookData!['bookLink'].isEmpty) {
              await fetchSubscriptionBookLink(widget.bookId, token);
            }
          } else {
            throw Exception("Access denied. Please purchase or subscribe.");
          }

          setState(() {
            isLoading = false;
          });
        } else {
          throw Exception("Invalid response: 'book' key is missing.");
        }
      } else {
        throw Exception("Failed to fetch book details. Status: ${response.statusCode}");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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
              color: Colors.black,
              fontFamily: 'SF-Pro-Text',
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
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
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'SF-Pro-Text',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.black),
          elevation: 0,
        ),
        body: Center(child: Text("Failed to load book details.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Detail Page",
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.black),
            onPressed: () async {
              final sharableLink =
                  "https://Readme.com/detail?bookId=${widget.bookId}";
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          child: Icon(
                            Icons.broken_image,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white70
                                : Colors.grey,
                          ),
                        );
                      },
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.teal.shade50,
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
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
                              style: TextStyle(
                                fontFamily: 'SF-Pro-Text',
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
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
                          bookData!['free'] ? "Free" : '\$${bookData!['price']}',
                          style: TextStyle(
                            fontFamily: 'SF-Pro-Text',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.remove_red_eye,
                                size: 16,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white70
                                    : Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              "${bookData!['numberOfViews']}",
                              style: TextStyle(
                                fontFamily: 'SF-Pro-Text',
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),

              Column(
                children: [
                  Wrap(
                    spacing: 73.0,
                    runSpacing: 22.0,
                    alignment: WrapAlignment.center,
                    children: [
                      buildActionButton(
                        (bookData!['isFavorited'] ?? false) ? Icons.favorite : Icons.favorite_border,
                        "Favorite",
                            () async {
                          await toggleFavorite();
                          setState(() {
                            bookData!['isFavorited'] = !(bookData!['isFavorited'] ?? false);
                          });
                        },
                        color: (bookData!['isFavorited'] ?? false)
                            ? Colors.red
                            : Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey
                            : Colors.black,
                      ),
                      buildActionButton(
                        Icons.download,
                        "Download",
                            () async {
                          final hasAccess = await checkUserAccess(bookData!['_id'], refreshDetails: true);
                          if (!hasAccess) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SubscriptionPage(),
                              ),
                            );
                            return;
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
                        },
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.tealAccent
                            : Colors.white,
                      ),
                      buildActionButton(
                        Icons.book,
                        "Read",
                            () async {
                          bool hasAccess = await checkUserAccess(bookData!['_id'], refreshDetails: true);
                          if (!hasAccess) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SubscriptionPage()),
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
                            await incrementReadingHistory();
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
                        },
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blueAccent
                            : Colors.white,
                      ),

                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Wrap(
                    spacing: 73.0,
                    runSpacing: 22.0,
                    alignment: WrapAlignment.center,
                    children: [
                      buildActionButton(
                        Icons.text_snippet,
                        "Summarize",
                            () async {
                          final prefs = await SharedPreferences.getInstance();
                          String? token = prefs.getString('auth_token');
                          if (token == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Authentication Error: Please log in.")),
                            );
                            return;
                          }
                          final url =
                              'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/${widget.bookId}/summary';
                          try {
                            final response = await http.get(
                              Uri.parse(url),
                              headers: {'Authorization': 'Bearer $token'},
                            );
                            if (response.statusCode == 200) {
                              final data = json.decode(response.body);
                              final bookName = bookData?['title'] ?? "Unknown Book";
                              final summaryText = data['summary'] ?? "No summary available.";
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SummaryPage(
                                    bookName: bookName,
                                    summaryText: summaryText,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: Failed to fetch summary.")),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Network Error: $e")),
                            );
                          }
                        },
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.tealAccent
                            : Colors.white,
                      ),
                      buildActionButton(
                        Icons.headphones,
                        "Listen",
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ListenPage(bookId: widget.bookId),
                            ),
                          );
                        },
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.tealAccent
                            : Colors.white,
                      ),
                      buildActionButton(
                        Icons.report,
                        "Report",
                            () async {
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
                        },
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange
                            : Colors.white,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20),

              Text(
                "About this book",
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              SizedBox(height: 7),
              Text(
                bookData!['description'] ?? "No description available.",
                style: TextStyle(
                  fontFamily: 'SF-Pro-Text',
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.tealAccent
                          : Color(0xFF5AA5B1),
                    ),
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
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[300]
                          : Colors.black,
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
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.tealAccent
                      : Color(0xFF5AA5B1),
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
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.redAccent
                        : Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget buildActionButton(IconData icon, String label, VoidCallback onPressed, {required Color color}) {
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