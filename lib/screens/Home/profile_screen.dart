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

        if (data['success'] == true) {
          setState(() {
            email = data['user']['email'];
            fullName = data['user']['fullName'];
            gender = data['user']['gender'];
            phoneNumber = data['user']['phoneNumber'];
            profilePicture = data['user']['profilePicture'];
            isLoading = false;
          });
        } else {
          throw Exception('Failed to fetch user details.');
        }
      } else {
        throw Exception('Server Error: ${response.statusCode}');
      }
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            backgroundColor: Colors.white,
            backgroundImage: profilePicture != null && profilePicture!.startsWith('http')
                ? NetworkImage(profilePicture!)
                : const AssetImage('assets/images/user_placeholder.png') as ImageProvider,
          ),
          const SizedBox(height: 15),
          Text(
            fullName ?? "Loading full name...",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email ?? "Loading email...",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.pink, Colors.orange],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.book, size: 20),
            text: 'Books',
          ),
          Tab(
            icon: Icon(Icons.subscriptions, size: 20),
            text: 'Subscriptions',
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
