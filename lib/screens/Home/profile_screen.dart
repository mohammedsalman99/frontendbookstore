import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Details/editprofile.dart';
import '../Details/mydownload.dart';
import '../Details/myfavorits.dart';
import '../auth/login.dart';
import '../setting/setting.dart';

class AdvancedProfileScreen extends StatefulWidget {
  const AdvancedProfileScreen({Key? key}) : super(key: key);

  @override
  _AdvancedProfileScreenState createState() => _AdvancedProfileScreenState();
}

class _AdvancedProfileScreenState extends State<AdvancedProfileScreen> {
  String? email;
  String? token;
  String? fullName;
  String? gender;
  String? phoneNumber;
  String? profilePicture;
  bool isLoading = true;
  List<dynamic> purchasedBooks = [];
  List<dynamic> subscriptions = [];
  bool isBooksLoading = true;
  bool isSubscriptionsLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserDetails().then((_) {
      if (token != null) {
        fetchPurchasedBooks();
        fetchSubscriptions();
      }
    });
  }


  Future<void> fetchPurchasedBooks() async {
    try {
      setState(() => isBooksLoading = true);
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/books/purchased'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          purchasedBooks = data['purchases'] ?? [];
          isBooksLoading = false;
        });
        print('Purchased books count: ${purchasedBooks.length}');
      } else {
        throw Exception('Failed to fetch books: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching books: $error');
      setState(() => isBooksLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading books: $error')),
      );
    }
  }




  Future<void> fetchSubscriptions() async {
    print('fetchSubscriptions: Started fetching subscription details...');

    try {
      setState(() => isSubscriptionsLoading = true);
      print('fetchSubscriptions: isSubscriptionsLoading set to true.');

      if (token == null) {
        print('fetchSubscriptions: Token is null. Exiting...');
        throw Exception('Token is null. Cannot fetch subscriptions.');
      }

      print('fetchSubscriptions: Token is not null. Proceeding with API call.');

      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/subscriptions/details'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('fetchSubscriptions: API Response status: ${response.statusCode}');
      print('fetchSubscriptions: API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['subscription'] != null) {
          print('fetchSubscriptions: Subscription data found.');
          setState(() {
            subscriptions = [data['subscription']];
            isSubscriptionsLoading = false;
          });
          print('fetchSubscriptions: Subscriptions updated. isSubscriptionsLoading set to false.');
        } else {
          print('fetchSubscriptions: Subscription data is null or missing in response.');
          throw Exception('No subscription found in the API response.');
        }
      } else {
        print('fetchSubscriptions: API request failed with status code: ${response.statusCode}');
        throw Exception('Failed to fetch subscriptions: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('fetchSubscriptions: Error occurred: $error');
      setState(() => isSubscriptionsLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subscription details: $error')),
      );
    } finally {
      print('fetchSubscriptions: Completed.');
    }
  }



  Future<void> fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No auth token found. Please log in again.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data.containsKey('user')) {
          setState(() {
            email = data['user']['email'];
            fullName = data['user']['fullName'];
            gender = data['user']['gender'];
            phoneNumber = data['user']['phoneNumber'];
            profilePicture = data['user']['profilePicture'];
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response: user key not found.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}, Message: ${response.reasonPhrase}');
      }
    } catch (error, stackTrace) {
      print('Error in fetchUserDetails: $error');
      print('StackTrace: $stackTrace');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in fetching user details: $error')),
      );
    }
  }



  Future<void> updateUserProfile({
    required String updatedFullName,
    required String updatedGender,
    required String updatedPhoneNumber,
    required String updatedProfilePicture,
    required String updatedEmail,
    required String updatedPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final String? userId = prefs.getString('user_id');
    final String? authToken = prefs.getString('auth_token');

    if (userId == null || authToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID or Auth Token not found. Please log in again.')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'fullName': updatedFullName,
          'gender': updatedGender,
          'phoneNumber': updatedPhoneNumber,
          'profilePicture': updatedProfilePicture,
          'email': updatedEmail,
          if (updatedPassword.isNotEmpty) 'password': updatedPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData.containsKey('user')) {
          await prefs.setString('full_name', updatedFullName);
          await prefs.setString('gender', updatedGender);
          await prefs.setString('phone_number', updatedPhoneNumber);
          await prefs.setString('profile_picture', updatedProfilePicture);
          await prefs.setString('user_email', updatedEmail);

          setState(() {
            fullName = updatedFullName;
            gender = updatedGender;
            phoneNumber = updatedPhoneNumber;
            profilePicture = updatedProfilePicture;
            email = updatedEmail;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          throw Exception('Unexpected response: User data not found in response.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}, Message: ${response.reasonPhrase}');
      }
    } catch (error, stackTrace) {
      print('Error in updateUserProfile: $error');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in updating profile: $error')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }



  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white, // Adjust background color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black, // Adjust title color
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? Colors.white : Colors.black, // Adjust icon color
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings,
              color: isDarkMode ? Colors.white : Colors.black, // Adjust icon color
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Color(0xFF2E2E2E), Color(0xFF1E1E1E)] // Dark mode gradient
                  : [Color(0xFF5AA5B1), Color(0xFF87D1D3)], // Light mode gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 10),
            DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  _buildCustomTabBar(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        _buildHorizontalBooksTab(),
                        _buildHorizontalSubscriptionTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildUserOptions(context),
          ],
        ),
      ),
    );
  }



  Widget _buildProfileHeader() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Color(0xFF2E2E2E), Color(0xFF1E1E1E)] // Dark mode gradient
              : [Color(0xFF5AA5B1), Color(0xFF87D1D3)], // Light mode gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5) // Stronger shadow for dark mode
                : Colors.black.withOpacity(0.1), // Lighter shadow for light mode
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: isDarkMode ? Colors.grey[800] : Colors.white,
            backgroundImage: profilePicture != null && profilePicture!.startsWith('http')
                ? NetworkImage(profilePicture!)
                : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
          ),
          const SizedBox(height: 15),
          Text(
            fullName ?? "Loading full name...",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black, // Adjust text color
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email ?? "Loading email...",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDarkMode ? Colors.grey[400] : Colors.white70, // Adjust text color
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.grey[200], // Adjust background color
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.5) // Stronger shadow for dark mode
                : Colors.black.withOpacity(0.1), // Lighter shadow for light mode
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: isDarkMode
                ? [Colors.grey[700]!, Colors.grey[600]!] // Darker gradient for dark mode
                : [Color(0xFF5AA5B1), Color(0xFF87D1D3)], // Original gradient for light mode
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: isDarkMode ? Colors.black : Colors.white, // Adjust label color
        unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[600], // Adjust unselected label color
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.book, size: 30),
            text: 'Books',
          ),
          Tab(
            icon: Icon(Icons.subscriptions, size: 30),
            text: 'Subscriptions',
          ),
        ],
      ),
    );
  }



  Widget _buildHorizontalBooksTab() {
    if (isBooksLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (purchasedBooks.isEmpty) {
      return const Center(child: Text('No books purchased.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: purchasedBooks.map((purchase) {
          final book = purchase['book'];
          return Card(
            margin: const EdgeInsets.only(right: 10),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    book['image'] ?? 'https://example.com/placeholder.png',
                    height: 100,
                    width: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book['title'] ?? 'Unknown Title',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book['authors']?.first['fullName'] ?? 'Unknown Author',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }



  Widget _buildHorizontalSubscriptionTab() {
    if (isSubscriptionsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (subscriptions.isEmpty) {
      return const Center(
        child: Text(
          'No active subscriptions.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final subscription = subscriptions[0];
    final expiryDate = DateTime.parse(subscription['expiryDate']);
    final durationInDays = subscription['plan']['durationInDays'] ?? 0;
    final startDate = expiryDate.subtract(Duration(days: durationInDays));
    final now = DateTime.now();
    final daysLeft = durationInDays - now.difference(startDate).inDays;
    final isExpired = daysLeft <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF5AA5B1), Color(0xFF87D1D3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.subscriptions, size: 40, color: Colors.white),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription['plan']['planName'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Price: \$${subscription['plan']['price'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                        Text(
                          "Duration: ${durationInDays} days",
                          style: const TextStyle(fontSize: 14, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white54, thickness: 1, height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Expiry Date:",
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        expiryDate.toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isExpired ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isExpired ? "Expired" : "Active",
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isExpired ? "Expired" : "Days Left:",
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  Text(
                    isExpired ? "0 days" : "$daysLeft days",
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }






  Widget _buildUserOptions(BuildContext context) {
    return Column(
      children: [
        _buildOption(context, Icons.favorite, 'My Favorites', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyFavoritesPage(),
            ),
          );
        }),

        _buildOption(context, Icons.download, 'My Downloads', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyDownloadsPage(),
            ),
          );
        }),

        _buildOption(context, Icons.edit, 'Edit Profile', () async {
          final prefs = await SharedPreferences.getInstance();
          final userId = prefs.getString('user_id') ?? "";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                fullName: fullName,
                gender: gender,
                phoneNumber: phoneNumber,
                profilePicture: profilePicture,
                email: email,
                userId: userId,
                onProfileUpdated: fetchUserDetails,
              ),
            ),
          );
        }),

        _buildOption(context, Icons.delete, 'Delete My Account', () {
          _showConfirmationDialog(context, 'Delete My Account');
        }),
        _buildOption(context, Icons.logout, 'Logout', logout),
        const SizedBox(height: 65),
      ],
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label),
        onTap: onTap,
      ),
    );
  }



  void _showConfirmationDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text('Are you sure you want to $action?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                print('$action confirmed.');
              },
            ),
          ],
        );
      },
    );
  }
}
