import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareApp {
  static void share() {
    const String appLink = 'https://play.google.com/store/apps/details?id=com.example.yourapp';
    Share.share(
      'Check out this awesome app! Download it now: $appLink',
      subject: 'Try This App!',
    );
  }
}
