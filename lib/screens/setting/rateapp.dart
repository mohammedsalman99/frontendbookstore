import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RateApp {
  static Future<void> launchRateApp(BuildContext context) async {
    final Uri appStoreUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.example.app');

    // Save the current state before launching the external app
    await _saveCurrentState(context);

    try {
      if (await canLaunchUrl(appStoreUrl)) {
        await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
      } else {
        print("Could not launch $appStoreUrl");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open app store.')),
        );
      }
    } catch (e) {
      print("Error launching app store: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An error occurred while opening app store.')),
      );
    }
  }

  // Save the current route to SharedPreferences
  static Future<void> _saveCurrentState(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute != null) {
      print("Saving current route: $currentRoute");
      await prefs.setString('last_route', currentRoute);
    }
  }

  // Restore the last route on app resume
  static Future<String?> getLastRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRoute = prefs.getString('last_route');
    print("Retrieved last route: $lastRoute");
    return lastRoute;
  }
}
