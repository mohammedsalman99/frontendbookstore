import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;

class SummaryPage extends StatelessWidget {
  final String bookName;
  final String summaryText;

  const SummaryPage({
    Key? key,
    required this.bookName,
    required this.summaryText,
  }) : super(key: key);

  Future<Uint8List> generatePdf() async {
    final pdf = pw.Document();

    final summaryChunks = summaryText.split('\n'); 
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text(
              bookName,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              "Summary:",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...summaryChunks.map((chunk) => pw.Text(
              chunk,
              style: pw.TextStyle(fontSize: 14),
            )),
          ];
        },
      ),
    );

    return pdf.save();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Summary of $bookName",
          style: TextStyle(
            fontFamily: 'SF-Pro-Text',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 5,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5AA5B1), Colors.teal.shade700],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder<Uint8List>(
          future: generatePdf(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Generating your summary...",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'SF-Pro-Text',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Error loading summary",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontFamily: 'SF-Pro-Text',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasData) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SfPdfViewer.memory(snapshot.data!),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              return Center(
                child: Text(
                  "No data to display",
                  style: TextStyle(
                    color: Colors.white70,
                    fontFamily: 'SF-Pro-Text',
                    fontSize: 16,
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }




Future<void> requestSummary(BuildContext context, String bookId) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Authentication Error: Please log in."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final url = 'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/$bookId/summary';

  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Summary Requested: ${data['message']}"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Failed to request summary."),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Network Error: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<String> getSummaryStatus(BuildContext context, String bookId) async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('auth_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Authentication Error: Please log in."),
        backgroundColor: Colors.red,
      ),
    );
    return "Authentication Error";
  }

  final url = 'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/$bookId/summary';

  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.containsKey('status')) {
        return data['status'];
      } else {
        return "Unexpected response format.";
      }
    } else {
      return "Error: Failed to fetch summary status. (${response.statusCode})";
    }
  } catch (e) {
    return "Network Error: $e";
  }
}

Widget buildSummaryButton(BuildContext context, String bookId) {
  return ElevatedButton(
    onPressed: () async {
      final prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('auth_token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Authentication Error: Please log in."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final url =
          'https://readme-backend-zdiq.onrender.com/api/v1/summary/books/$bookId/summary';

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final bookName = data['bookName'] ?? "Unknown Book";
          final summaryText = data['summary'] ?? "No summary available.";

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummaryPage(
                bookName: bookName,
                summaryText: summaryText,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: Failed to fetch summary."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Network Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    },
    child: Text("View Summary"),
  );
}
}
