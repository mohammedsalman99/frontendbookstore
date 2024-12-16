import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color(0xFF5AA5B1); 

    Widget _buildInfoTile(IconData icon, String title, String subtitle) {
      return Card(
        elevation: 2,
        margin: EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Icon(icon, color: primaryColor),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, 
        elevation: 1, 
        title: Text(
          "About Us",
          style: TextStyle(
            color: Colors.black87, 
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Colors.black87, 
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: primaryColor.withOpacity(0.2),
                    child: Icon(Icons.android, size: 50, color: primaryColor),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "README",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            _buildInfoTile(Icons.info, "App Version", "1.0.0"),
            _buildInfoTile(Icons.business, "Company", "README"),
            _buildInfoTile(Icons.email, "Email", "info@easy.com"),
            _buildInfoTile(Icons.language, "Website", "www.viaviweb.com"),
            _buildInfoTile(Icons.phone, "Contact", "+972595871796"),

            SizedBox(height: 16),
            Divider(thickness: 1),
            Text(
              "About Us",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Contrary to popular belief, Lorem Ipsum is not simply random text. It has roots in a piece of classical Latin literature from 45 BC, making it over 2000 years old. "
                  "Richard McClintock, a Latin professor at Hampden-Sydney College in Virginia, looked up one of the more obscure Latin words.",
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
