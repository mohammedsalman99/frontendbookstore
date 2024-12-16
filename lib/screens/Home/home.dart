import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../massage/messages_screen.dart';
import 'home_screen.dart';
import 'latest_screen.dart';
import 'authors_screen.dart';
import 'profile_screen.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _selectedIndex = 0;
  int _unreadMessages = 0; // Track unread message count

  final List<Widget> _screens = [
    HomeScreen(),
    LatestScreen(),
    AuthorsScreen(),
    AdvancedProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    fetchUnreadMessages(); // Fetch unread messages on app start
  }

  // Fetch unread message count from the backend
  Future<void> fetchUnreadMessages() async {
    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/messages'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = data['messages'] as List;

        // Count unread messages based on a condition (e.g., not viewed yet)
        final unreadCount = messages.where((message) => !message['isViewed']).length;

        setState(() {
          _unreadMessages = unreadCount;
        });
      } else {
        print('Failed to fetch unread messages: ${response.body}');
      }
    } catch (e) {
      print('Error fetching unread messages: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openMessagesScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MessagesScreen()),
    ).then((_) {
      // Clear unread messages after viewing
      setState(() {
        _unreadMessages = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Main screens
          _screens[_selectedIndex],
          // Floating message icon
          Positioned(
            bottom: 80, // Above the bottom navigation bar
            right: 16, // Aligned to the right
            child: GestureDetector(
              onTap: _openMessagesScreen,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular floating icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFF5AA5B1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.message,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  // Unread badge
                  if (_unreadMessages > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$_unreadMessages',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class CustomBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomBottomNavigationBar({
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5AA5B1), Color(0xFF3D7A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, "Home", 0),
          _buildNavItem(Icons.new_releases, "Latest", 1),
          _buildNavItem(Icons.person, "Author", 2),
          _buildNavItem(Icons.account_circle, "Profile", 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        decoration: isSelected
            ? BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(15),
        )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isSelected ? 24 : 20,
              color: isSelected ? Colors.white : Colors.white70,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SF-Pro-Text',
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
