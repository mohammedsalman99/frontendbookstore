import 'package:flutter/material.dart';
import 'package:frontend/screens/setting/termofuse.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'aboutus.dart';
import 'theme_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'rateapp.dart';
import 'shareapp.dart'; 
import 'privacypolicy.dart'; 

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
    _loadCacheSize(); 
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
      final Directory cacheDir = Directory(await getTemporaryDirectoryPath());
      if (cacheDir.existsSync()) {
        for (final file in cacheDir.listSync()) {
          if (file is File) {
            totalSize += file.lengthSync();
          }
        }
      }
    } catch (e) {
      print("Error calculating cache size: $e");
    }
    return totalSize / (1024 * 1024);
  }

  Future<void> _clearCache() async {
    print("Clearing cache...");
    try {
      final Directory cacheDir = Directory(await getTemporaryDirectoryPath());
      if (cacheDir.existsSync()) {
        for (final file in cacheDir.listSync()) {
          file.deleteSync(recursive: true);
        }
      }
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
      cacheSize = size;
    });
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Color(0xFF5AA5B1),
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        centerTitle: true, 
        iconTheme: IconThemeData(color: Colors.white), 
      ),

      body: ListView(
        children: [
          ListTile(
            leading: Icon(
              Icons.notifications,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Enable Push Notification',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Switch.adaptive(
              value: isNotificationEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationEnabled = value;
                  _saveNotificationPreference(value);
                });
              },
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.refresh,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Clear Cache',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            subtitle: Text(
              '${cacheSize.toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () async {
              await _clearCache();
              final size = await _calculateCacheSize();
              setState(() {
                cacheSize = size;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cache cleared successfully!',
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  ),
                  backgroundColor: Theme.of(context).cardColor,
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.brightness_6,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(
              'Dark Mode',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            trailing: Switch.adaptive(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AboutUsPage()),
              );
            },
          ),
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
              RateApp.launchRateApp(context);
            },
          ),
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
            onTap: () {
              ShareApp.share(); 
            },
          ),

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
              );
            },
          ),

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfUsePage()),
              );
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


  void _showAboutUsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AboutUsPage()),
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
