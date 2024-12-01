import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../Details/editprofile.dart';
import '../auth/login.dart';

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

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('user_email');
      token = prefs.getString('auth_token');
      fullName = prefs.getString('full_name') ?? "None";
      gender = prefs.getString('gender') ?? "Not Specified";
      phoneNumber = prefs.getString('phone_number') ?? "Not Provided";
      profilePicture = prefs.getString('profile_picture') ?? 'assets/images/user_placeholder.png';
      isLoading = false;
    });
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
    setState(() => isLoading = true);

    try {
      final response = await http.put(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/${prefs.getString('user_id')}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${prefs.getString('auth_token')}',
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
        if (responseData['success'] == true) {
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
            SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          throw Exception('Failed to update profile.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
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
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: logout,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
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
                  SizedBox(
                    height: 250,
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
            const SizedBox(height: 10),
            _buildUserOptions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          backgroundImage: profilePicture != null
              ? NetworkImage(profilePicture!)
              : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
        ),
        const SizedBox(height: 20),
        Text(
          fullName ?? "Loading full name...",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          email ?? "Loading email...",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Gender: ${gender ?? "Not Specified"}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Phone: ${phoneNumber ?? "Not Provided"}",
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[700],
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.book, size: 18),
            child: Text(
              'Purchased Books',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Tab(
            icon: Icon(Icons.subscriptions, size: 18),
            child: Text(
              'Subscription',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBooksTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [],
      ),
    );
  }

  Widget _buildHorizontalSubscriptionTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [],
      ),
    );
  }

  Widget _buildUserOptions(BuildContext context) {
    return Column(
      children: [
        _buildOption(context, Icons.favorite, 'My Favorites', () {
          print('Navigating to My Favorites');
        }),
        _buildOption(context, Icons.download, 'My Downloads', () {
          print('Navigating to My Downloads');
        }),
        _buildOption(context, Icons.edit, 'Edit Profile', () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                fullName: fullName,
                gender: gender,
                phoneNumber: phoneNumber,
                profilePicture: profilePicture,
                email: email,
                userId: "YOUR_USER_ID", 
              ),
            ),
          );
        }),
        _buildOption(context, Icons.delete, 'Delete My Account', () {
          _showConfirmationDialog(context, 'Delete My Account');
        }),
        _buildOption(context, Icons.logout, 'Logout', logout),
        const SizedBox(height: 20),
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
