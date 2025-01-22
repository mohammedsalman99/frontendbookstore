import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ReportPage extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  ReportPage({
    required this.bookId,
    required this.bookTitle,
  });

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final description = _descriptionController.text.trim();

    if (description.length <= 10) {
      setState(() {
        _errorText = "Description must be more than 10 characters.";
      });
      return;
    }

    final reportData = {"description": description};
    final String apiUrl =
        "https://readme-backend-zdiq.onrender.com/api/v1/books/${widget.bookId}/reports";

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showAdvancedMessage(
          context,
          "Authentication Error",
          "Please log in to submit a report.",
          isError: true,
        );
        return;
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(reportData),
      );
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          _showAdvancedMessage(
            context,
            "Report Submitted",
            "Your report has been submitted successfully.",
            isError: false,
          );
          Navigator.pop(context); 
        }
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);

        if (responseData['message'] == "You have already reported this book") {
          _showAdvancedMessage(
            context,
            "Duplicate Report",
            "You have already reported this book.",
            isError: true,
          );
        } else {
          _showAdvancedMessage(
            context,
            "Invalid Data",
            "Invalid report data. Please try again.",
            isError: true,
          );
        }
      } else if (response.statusCode >= 500) {
        _showAdvancedMessage(
          context,
          "Server Error",
          "There was a problem on our end. Please try again later.",
          isError: true,
        );
      } else {
        _showAdvancedMessage(
          context,
          "Unexpected Error",
          "Something went wrong. Please try again.",
          isError: true,
        );
      }
    } catch (e) {
      _showAdvancedMessage(
        context,
        "Network Error",
        "Please check your internet connection and try again.",
        isError: true,
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showAdvancedMessage(
      BuildContext context, String title, String message,
      {required bool isError}) {
    final backgroundColor = isError ? Colors.red.shade100 : Colors.green.shade100;
    final icon = isError ? Icons.error : Icons.check_circle;
    final iconColor = isError ? Colors.red : Colors.green;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: iconColor,
                    ),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        elevation: 8.0,
        margin: EdgeInsets.all(12),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Report Book"),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: _isSubmitting
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5AA5B1),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            Text(
              "Describe the issue:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: "Write details here...",
                errorText: _errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5AA5B1),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "SUBMIT",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
