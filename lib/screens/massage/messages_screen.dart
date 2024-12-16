import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../auth/login.dart'; // Replace with your LoginPage path if needed

class MessagesScreen extends StatefulWidget {
  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> messages = [];
  bool isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  String? authToken;
  String? profilePictureUrl; // Holds the user's profile picture URL


  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }


  // Check if user is authenticated
  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    if (authToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      fetchMessages();       // Fetch chat messages
    }
  }


  // Fetch messages from the backend
  Future<void> fetchMessages() async {
    print("Fetching messages...");
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/messages'),
        headers: {'Authorization': 'Bearer $authToken'},
      );

      print("Fetch Messages Response: ${response.statusCode}");
      print("Fetch Messages Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data['messages'];
          isLoading = false;
        });
      } else {
        showError('Failed to fetch messages');
      }
    } catch (e, stacktrace) {
      print("Error while fetching messages: $e");
      print("Stacktrace: $stacktrace");
      showError('An error occurred while fetching messages');
    }
  }

  // Send a new message to the backend
  // Send a new message to the backend
  Future<void> sendMessage({required String message, File? file}) async {
    print("Sending message...");

    // Add the message locally for instant UI feedback
    final newMessage = {
      'body': message,
      'sentBy': 'user',
      'timestamp': {'_seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000},
      'attachment': file?.path, // Use file path for attachment preview if applicable
    };

    setState(() {
      messages.insert(0, newMessage); // Add the message to the top of the list
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        print("Error: Auth token is null. Redirecting to login...");
        showError("User not authenticated. Please log in.");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        return;
      }

      print("Auth Token: Bearer $authToken");

      if (file == null) {
        // Text-only message (JSON request)
        final response = await http.post(
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'message': message}),
        );

        print("Send Message Response: ${response.statusCode}");
        print("Response Body: ${response.body}");

        if (response.statusCode != 200) {
          showError('Failed to send message');
          print("Error: ${response.body}");
        }
      } else {
        // Message with file attachment (Multipart request)
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/send'),
        );

        request.headers['Authorization'] = 'Bearer $authToken';
        request.fields['message'] = message;

        print("Attaching file: ${file.path}");
        request.files.add(
          await http.MultipartFile.fromPath('attachment', file.path),
        );

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        print("Send Message Response: ${response.statusCode}");
        print("Response Body: $responseBody");

        if (response.statusCode != 200) {
          showError('Failed to send message');
          print("Error: $responseBody");
        }
      }
    } catch (e, stacktrace) {
      print("Error while sending message: $e");
      print("Stacktrace: $stacktrace");
      showError('An error occurred while sending the message.');
    }
  }



  // Show error message
  void showError(String message) {
    print("Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      isLoading = false;
    });
  }

  // Pick an image
  Future<File?> pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        print("Picked Image: ${pickedFile.path}");
        return File(pickedFile.path);
      } else {
        print("No image selected.");
        return null;
      }
    } catch (e, stacktrace) {
      print("Error while picking image: $e");
      print("Stacktrace: $stacktrace");
      return null;
    }
  }

  // Pick a file
  Future<File?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && result.files.single.path != null) {
        print("Picked File: ${result.files.single.path}");
        return File(result.files.single.path!);
      } else {
        print("No file selected.");
        return null;
      }
    } catch (e, stacktrace) {
      print("Error while picking file: $e");
      print("Stacktrace: $stacktrace");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messages"),
        backgroundColor: Color(0xFF5AA5B1),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Show latest messages at the bottom
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isSentByUser = message['sentBy'] == 'user';
                final attachmentUrl = message['attachment'];

                return Align(
                  alignment: isSentByUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSentByUser
                          ? Color(0xFF5AA5B1) // User message color
                          : Colors.white, // Admin message color
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                        bottomLeft: isSentByUser
                            ? Radius.circular(12)
                            : Radius.zero,
                        bottomRight: isSentByUser
                            ? Radius.zero
                            : Radius.circular(12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 3,
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (attachmentUrl != null)
                          GestureDetector(
                            onTap: () {
                              print("Opening attachment: $attachmentUrl");
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                attachmentUrl,
                                height: 150,
                                width: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Text(
                                    "Failed to load image",
                                    style: TextStyle(
                                      color: isSentByUser
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        if (message['body'] != null &&
                            message['body'].isNotEmpty)
                          Text(
                            message['body'],
                            style: TextStyle(
                              fontSize: 14,
                              color: isSentByUser
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message['timestamp']),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSentByUser
                                ? Colors.white70
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.photo, color: Color(0xFF5AA5B1)),
                  onPressed: () async {
                    final file = await pickImage();
                    if (file != null) {
                      sendMessage(message: '', file: file);
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.attach_file,
                      color: Color(0xFF5AA5B1)),
                  onPressed: () async {
                    final file = await pickFile();
                    if (file != null) {
                      sendMessage(message: '', file: file);
                    }
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Color(0xFF5AA5B1)),
                  onPressed: () {
                    final message = _messageController.text.trim();
                    if (message.isNotEmpty) {
                      // Add message locally and clear input
                      setState(() {
                        messages.insert(0, {
                          'body': message,
                          'sentBy': 'user',
                          'timestamp': {
                            '_seconds': DateTime.now()
                                .millisecondsSinceEpoch ~/
                                1000
                          },
                          'attachment': null,
                        });
                      });
                      sendMessage(message: message);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }




  // Format timestamp
  String _formatTimestamp(dynamic timestamp) {
    final seconds = timestamp['_seconds'];
    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; // Format HH:mm
  }
}
