import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PurchaseBookPage extends StatefulWidget {
  final String bookId;
  final double amount;

  const PurchaseBookPage({Key? key, required this.bookId, required this.amount}) : super(key: key);

  @override
  _PurchaseBookPageState createState() => _PurchaseBookPageState();
}

class _PurchaseBookPageState extends State<PurchaseBookPage> {
  bool isLoading = false;

  Future<void> createTransaction() async {
    setState(() {
      isLoading = true;
    });

    final purchaseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/purchase';
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showSnackBar("Authentication Error", "Please log in to proceed.", isError: true);
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(purchaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({}), 
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authorizationUrl = data['payment']?['authorization_url'];

        if (authorizationUrl != null) {
          await _openAuthorizationUrl(authorizationUrl);
        } else {
          _showSnackBar(
            "Transaction Error",
            "Payment URL not provided in the response.",
            isError: true,
          );
        }
      } else if (response.statusCode == 404) {
        _showSnackBar("Error", "Book not found.", isError: true);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        _showSnackBar("Error", error['message'], isError: true);
      } else if (response.statusCode == 500) {
        final error = json.decode(response.body);
        _showSnackBar(
          "Server Error",
          error['message'] ?? "Error processing book purchase.",
          isError: true,
        );
      } else {
        _showSnackBar(
          "Unexpected Error",
          "An unexpected error occurred. Please try again later.",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar("Error", "An unexpected error occurred: $e", isError: true);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  Future<void> completePurchase(String transactionId) async {
    final purchaseUrl =
        'https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/purchase';
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      _showSnackBar(
        "Authentication Error",
        "Please log in to complete your purchase.",
        isError: true,
      );
      return;
    }

    try {
      final body = jsonEncode({"transactionId": transactionId});

      final response = await http.post(
        Uri.parse(purchaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _showSnackBar(
          "Purchase Successful",
          data['message'] ?? "Thank you! Enjoy your book.",
          isError: false,
        );

        Navigator.pop(context); 
      } else {
        final error = json.decode(response.body);
        _showSnackBar(
          "Purchase Error",
          error['message'] ?? "Purchase confirmation failed.",
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        "Network Error",
        "An unexpected error occurred: $e",
        isError: true,
      );
    }
  }

  Future<void> _openAuthorizationUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url, forceSafariVC: true, forceWebView: false); 
    } else {
      _showSnackBar("Error", "Could not open the payment URL.", isError: true);
    }
  }

  void _showSnackBar(String title, String message, {required bool isError}) {
    final backgroundColor = isError ? Colors.red.shade100 : Colors.green.shade100;
    final iconColor = isError ? Colors.red : Colors.green;
    final icon = isError ? Icons.error : Icons.check_circle;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: iconColor),
                  ),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Book"),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
          onPressed: createTransaction,
          child: const Text("Pay Now"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
