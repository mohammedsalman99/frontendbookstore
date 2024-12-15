import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Make sure you have the ThemeProvider class defined
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
    _loadCacheSize(); // Load cache size on startup
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

      final authToken = await _getAuthToken();
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
          'Authorization': 'Bearer $authToken',
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

      final authToken = await _getAuthToken();
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
          'Authorization': 'Bearer $authToken',
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

  Future<double> _calculateCacheSize() async {
    double totalSize = 0.0;

    try {
      // Get cache directory path
      final Directory cacheDir = Directory(await getTemporaryDirectoryPath());

      // Ensure directory exists
      if (cacheDir.existsSync()) {
        // Iterate through cache files and calculate total size
        for (final file in cacheDir.listSync()) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
      }
    } catch (e) {
      print("Error calculating cache size: $e");
    }

    // Convert bytes to megabytes (MB)
    return totalSize / (1024 * 1024);
  }

  Future<void> _clearCache() async {
    print("Clearing cache...");
    try {
      // Get cache directory path
      final Directory cacheDir = Directory(await getTemporaryDirectoryPath());

      // Ensure directory exists
      if (cacheDir.existsSync()) {
        // Delete all files and directories in the cache
        for (final file in cacheDir.listSync()) {
          file.deleteSync(recursive: true);
        }
      }

      // Update UI and cache size
      setState(() {
        cacheSize = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cache cleared successfully!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          backgroundColor: Theme.of(context).cardColor,
        ),
      );
      print("Cache cleared successfully.");
    } catch (e) {
      print("Error clearing cache: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error clearing cache: $e',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String> getTemporaryDirectoryPath() async {
    try {
      final Directory tempDir = Directory.systemTemp;
      return tempDir.path;
    } catch (e) {
      print("Error retrieving temporary directory: $e");
      throw Exception("Unable to retrieve temporary directory.");
    }
  }
  Future<void> _loadCacheSize() async {
    final size = await _calculateCacheSize();
    setState(() {
      cacheSize = size; // Update cache size dynamically
    });
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dynamic background
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white), // Dynamic AppBar title
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // Push Notification Toggle
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).iconTheme.color, // Dynamic icon color
            ),
            title: Text(
              'Enable Push Notification',
              style: Theme.of(context).textTheme.bodyLarge, // Dynamic text style
            ),
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
          // Clear Cache Option
          ListTile(
            leading: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color, // Dynamic icon color
            ),
            title: Text(
              'Clear Cache',
              style: Theme.of(context).textTheme.bodyLarge, // Dynamic text style
            ),
            subtitle: Text(
              '${cacheSize.toStringAsFixed(1)} MB', // Display current cache size dynamically
              style: Theme.of(context).textTheme.bodyMedium, // Secondary text style
            ),
            onTap: () async {
              print("Clear cache tapped.");
              await _clearCache(); // Clear cache
              final size = await _calculateCacheSize(); // Recalculate cache size
              setState(() {
                cacheSize = size; // Update UI with new cache size
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cache cleared successfully!',
                    style: Theme.of(context).textTheme.bodyLarge, // Dynamic text style
                  ),
                  backgroundColor: Theme.of(context).cardColor, // Dynamic SnackBar color
                ),
              );
            },
          ),
          // Dark Mode Toggle
          ListTile(
            leading: Icon(
              Icons.brightness_6,
              color: Theme.of(context).iconTheme.color, // Dynamic icon color
            ),
            title: Text(
              'Dark Mode',
              style: Theme.of(context).textTheme.bodyLarge, // Dynamic text style
            ),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value); // Toggle dark/light mode
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value ? 'Dark Mode Enabled' : 'Light Mode Enabled',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                );
              },
            ),
          ),
          // About Us
          ListTile(
            leading: Icon(
              Icons.info,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'About Us',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              _showAboutUsDialog(context);
            },
          ),
          // Rate App
          ListTile(
            leading: Icon(
              Icons.star_rate,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Rate App',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              _rateApp();
            },
          ),
          // Share App
          ListTile(
            leading: Icon(
              Icons.share,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Share App',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {},
          ),
          // Privacy Policy
          ListTile(
            leading: Icon(
              Icons.privacy_tip,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),
          // Terms of Use
          ListTile(
            leading: Icon(
              Icons.description,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Terms of Use',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).iconTheme.color,
            ),
            onTap: () {
              _showTermsOfUse(context);
            },
          ),
        ],
      ),
    );
  }



  void _changeTheme(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    themeProvider.toggleTheme(!isDarkMode);
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
