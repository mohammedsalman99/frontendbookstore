import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Privacy Policy',
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
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFF5AA5B1),
                        child: Icon(Icons.book, color: Colors.white, size: 50),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Our Book Store',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5AA5B1),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your trusted partner for knowledge and entertainment.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                _buildExpandableSection(
                  title: 'Data Collection',
                  content: '''
- Personal Information : Includes your name, email, and address for creating and managing accounts.

- Purchase History : Collected to recommend relevant books and ensure seamless purchases.

- Device Information : Device model, IP address, and usage patterns are collected for app optimization.''',
                  icon: Icons.data_usage,
                ),

                _buildExpandableSection(
                  title: 'How We Use Your Data',
                  content: '''
- To personalize your reading experience by offering tailored book recommendations.

- To improve app performance and ensure the security of your data.

- To notify you of new arrivals, exclusive discounts, and updates.''',
                  icon: Icons.verified_user,
                ),

                _buildExpandableSection(
                  title: 'Third-Party Services',
                  content: '''
We may share data with trusted partners for:

- Payment Processing : Securely processing transactions using encrypted gateways.

- Analytics : Services like Google Analytics help us improve the app.

- Delivery Services : For shipping physical books to your address.''',
                  icon: Icons.supervised_user_circle,
                ),

                _buildExpandableSection(
                  title: 'Security Measures',
                  content: '''
-  Encryption : All sensitive data is encrypted during transmission and storage.

-  Access Control : Only authorized personnel can access your data.

-  Regular Updates : Our systems are regularly audited to ensure security compliance.''',
                  icon: Icons.lock_outline,
                ),

                _buildExpandableSection(
                  title: 'Your Rights',
                  content: '''
- Access and Control : View or update your personal information anytime through your profile.

- Data Deletion : You can request account deletion to erase your data from our servers.

- Manage Preferences : Opt-in or opt-out of notifications and personalized recommendations.''',
                  icon: Icons.privacy_tip,
                ),

                SizedBox(height: 20),
                _buildFooterSection(),
                SizedBox(height: 80), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(icon, color: Color(0xFF5AA5B1)),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              content,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Card(
      color: Color(0xFF5AA5B1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank You for Trusting Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Our commitment is to provide you with the best reading experience while safeguarding your privacy.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
