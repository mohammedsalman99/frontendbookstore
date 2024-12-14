import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isNotificationEnabled = false;
  double cacheSize = 16.5;
  final String registerUrl =
      'https://readme-backend-zdiq.onrender.com/api/v1/notifications/register-token';
  final String unregisterUrl =
      'https://readme-backend-zdiq.onrender.com/api/v1/notifications/unregister-token';

  @override
  void initState() {
    super.initState();
    print("SettingsPage initialized.");
    _loadNotificationPreference();
  }
  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      print("Retrieved auth token: $token");
      return token;
    } catch (e) {
      print("Error retrieving auth token: $e");
      return null;
    }
  }


  Future<void> _loadNotificationPreference() async {
    print("Loading notification preference...");
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        isNotificationEnabled = prefs.getBool('isNotificationEnabled') ?? false;
        print("Notification preference loaded: $isNotificationEnabled");
      });
    } catch (e) {
      print("Error loading notification preference: $e");
    }
  }

  Future<void> _saveNotificationPreference(bool value) async {
    print("Saving notification preference: $value");
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isNotificationEnabled', value);
      print("Notification preference saved successfully.");

      if (value) {
        _registerFCMToken();
      } else {
        _unregisterFCMToken();
      }
    } catch (e) {
      print("Error saving notification preference: $e");
    }
  }

  Future<void> _registerFCMToken() async {
    print("Registering FCM token...");
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("Retrieved FCM token: $fcmToken");

      if (fcmToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token could not be retrieved.')),
        );
        print("FCM token retrieval failed.");
        return;
      }

      final authToken = await _getAuthToken(); // Get the auth token
      if (authToken == null) {
        print("Authorization token is missing.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization token is missing. Please log in.')),
        );
        return;
      }

      final deviceName = _getDeviceName();
      print("Device name: $deviceName");

      final response = await http.post(
        Uri.parse(registerUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Include the auth token
        },
        body: jsonEncode({
          'fcmToken': fcmToken,
          'device': deviceName,
        }),
      );

      print("Register token response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Token registered successfully')),
        );
        print("Token registered successfully: ${data['message']}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register FCM token: ${response.statusCode}')),
        );
        print("Failed to register FCM token. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error registering FCM token: $e')),
      );
      print("Error registering FCM token: $e");
    }
  }

  Future<void> _unregisterFCMToken() async {
    print("Unregistering FCM token...");
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print("Retrieved FCM token for unregistration: $fcmToken");

      if (fcmToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FCM token could not be retrieved.')),
        );
        print("FCM token retrieval failed for unregistration.");
        return;
      }

      final authToken = await _getAuthToken(); // Get the auth token
      if (authToken == null) {
        print("Authorization token is missing.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authorization token is missing. Please log in.')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse(unregisterUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken', // Include the auth token
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      print("Unregister token response: ${response.statusCode} - ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Token unregistered successfully')),
        );
        print("Token unregistered successfully: ${data['message']}");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unregister FCM token: ${response.statusCode}')),
        );
        print("Failed to unregister FCM token. Status code: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unregistering FCM token: $e')),
      );
      print("Error unregistering FCM token: $e");
    }
  }


  String _getDeviceName() {
    try {
      if (Platform.isAndroid) {
        return 'Android Device';
      } else if (Platform.isIOS) {
        return 'iOS Device';
      } else {
        return 'Unknown Device';
      }
    } catch (e) {
      print("Error getting device name: $e");
      return 'Unknown Device';
    }
  }

  Future<void> _clearCache() async {
    print("Clearing cache...");
    try {
      setState(() {
        cacheSize = 0.0;
      });
      print("Cache cleared successfully.");
    } catch (e) {
      print("Error clearing cache: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Enable Push Notification'),
            trailing: Switch(
              value: isNotificationEnabled,
              onChanged: (value) {
                print("Push Notification toggled: $value");
                setState(() {
                  isNotificationEnabled = value;
                  _saveNotificationPreference(value);
                });
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Clear Cache'),
            subtitle: Text('${cacheSize.toStringAsFixed(1)} MB'),
            onTap: () async {
              print("Clear cache tapped.");
              await _clearCache();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Theme Mode'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _changeTheme(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showAboutUsDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_rate),
            title: const Text('Rate App'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _rateApp();
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),
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

  void _changeTheme(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Theme switching is not yet implemented!')),
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About Us'),
          content: const Text(
              'This is a sample app developed to showcase settings functionality.'),
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

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to app store...')),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaceholderPage(title: 'Privacy Policy'),
      ),
    );
  }

  void _showTermsOfUse(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PlaceholderPage(title: 'Terms of Use'),
      ),
    );
  }
}

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
