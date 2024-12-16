import 'package:flutter/material.dart';

class TermsOfUsePage extends StatelessWidget {
  const TermsOfUsePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Terms of Use',
          style: TextStyle(
            color: Color(0xFF5AA5B1),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Color(0xFF5AA5B1)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFF5AA5B1),
                        child: Icon(Icons.gavel, color: Colors.white, size: 50),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Our Terms of Use',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5AA5B1),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Please read these terms carefully before using our services.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Introduction
                _buildSection(
                  title: 'Introduction',
                  content: '''
Welcome to our Bookstore app. By accessing or using our platform, you agree to be bound by these Terms of Use. If you do not agree with any part of these terms, please do not use our services.''',
                ),

                // User Obligations
                _buildSection(
                  title: 'User Obligations',
                  content: '''
- Provide accurate and up-to-date information during registration.
- Maintain the confidentiality of your account credentials.
- Use the app for personal and non-commercial purposes only.''',
                ),

                // Prohibited Activities
                _buildSection(
                  title: 'Prohibited Activities',
                  content: '''
- Using the app for illegal activities or fraud.
- Harming, harassing, or abusing other users.
- Distributing or reselling content without authorization.''',
                ),

                // Payment Terms
                _buildSection(
                  title: 'Payment Terms',
                  content: '''
- Prices for books and subscriptions are subject to change without notice.
- Refunds will be processed as per our refund policy.
- Ensure secure payment methods when making purchases.''',
                ),

                // Intellectual Property
                _buildSection(
                  title: 'Intellectual Property',
                  content: '''
All content on this app, including text, images, and logos, is owned by the Bookstore. Unauthorized use, reproduction, or distribution of our content is strictly prohibited.''',
                ),

                // Limitation of Liability
                _buildSection(
                  title: 'Limitation of Liability',
                  content: '''
We are not liable for any damages arising from:
- Errors or inaccuracies in content.
- Unauthorized access to your account.
- Third-party actions or services linked to our platform.''',
                ),

                // Termination
                _buildSection(
                  title: 'Termination',
                  content: '''
We reserve the right to suspend or terminate your account for violations of these terms or illegal activities.''',
                ),

                // Governing Law
                _buildSection(
                  title: 'Governing Law',
                  content: '''
These Terms of Use are governed by the laws of your jurisdiction. Disputes will be resolved in accordance with these laws.''',
                ),

                SizedBox(height: 80), // Space for footer
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Section Builder
  Widget _buildSection({required String title, required String content}) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
