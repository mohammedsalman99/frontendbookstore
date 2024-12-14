import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationEnabled = false; // State for the toggle switch
  double cacheSize = 16.5; // Example cache size in MB

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Enable Push Notification
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Enable Push Notification'),
            trailing: Switch(
              value: isNotificationEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationEnabled = value;
                  // Save the notification state to SharedPreferences
                  _saveNotificationPreference(value);
                });
              },
            ),
          ),

          // Clear Cache
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Clear Cache'),
            subtitle: Text('${cacheSize.toStringAsFixed(1)} MB'),
            onTap: () async {
              await _clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!')),
              );
            },
          ),

          // Theme Mode
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Toggle light and dark theme (placeholder)
              _changeTheme(context);
            },
          ),

          // About Us
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutUsDialog(context);
            },
          ),

          // Rate App
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate App'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _rateApp();
            },
          ),

          // Share App
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
            },
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),

          // Terms of Use
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Use'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showTermsOfUse(context);
            },
          ),
        ],
      ),
    );
  }

  // Save Notification Preference
  Future<void> _saveNotificationPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotificationEnabled', value);
  }

  // Clear Cache Functionality
  Future<void> _clearCache() async {
    setState(() {
      cacheSize = 0.0;
    });
  }

  // Change Theme Functionality
  void _changeTheme(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme switching is not yet implemented!')),
    );
  }

  // Show About Us Dialog
  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About Us'),
          content: const Text('This is a sample app developed to showcase settings functionality.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Rate App Functionality (Example Placeholder)
  void _rateApp() {
    // Simulate opening the app store for rating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to app store...')),
    );
  }



  // Show Privacy Policy
  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaceholderPage(title: 'Privacy Policy'),
      ),
    );
  }

  // Show Terms of Use
  void _showTermsOfUse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaceholderPage(title: 'Terms of Use'),
      ),
    );
  }
}

// Placeholder Page for Privacy Policy and Terms of Use
class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Text('$title content goes here.'),
      ),
    );
  }
}
