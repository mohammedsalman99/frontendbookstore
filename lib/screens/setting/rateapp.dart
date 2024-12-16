import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RateApp {
  static Future<void> launchRateApp(BuildContext context) async {
    final Uri appStoreUrl = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.example.app'); // Replace with your app's URL

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
}
