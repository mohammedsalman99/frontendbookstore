import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../auth/login.dart'; 

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
  String? profilePictureUrl;


  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }


  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    authToken = prefs.getString('auth_token');
    if (authToken == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      fetchMessages();   
    }
  }

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
      } else if (response.statusCode == 500 && response.body.contains('NOT_FOUND')) {
        print("No messages found, initializing with an empty list.");
        setState(() {
          messages = [];
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

  Future<void> sendMessage({required String message, File? file}) async {
    print("Sending message...");

    final newMessage = {
      'body': message,
      'sentBy': 'user',
      'timestamp': {'_seconds': DateTime.now().millisecondsSinceEpoch ~/ 1000},
      'attachment': file?.path,
    };

    setState(() {
      messages.insert(0, newMessage);
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

      http.Response response;
      if (file == null) {
        response = await http.post(
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({'message': message}),
        );
      } else {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/chat/send'),
        );

        request.headers['Authorization'] = 'Bearer $authToken';
        request.fields['message'] = message;
        request.files.add(await http.MultipartFile.fromPath('attachment', file.path));

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      }

      print("Send Message Response: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode != 200) {
        showError('Failed to send message');
        print("Error: ${response.body}");
        setState(() {
          messages.removeAt(0); 
        });
      }
    } catch (e, stacktrace) {
      print("Error while sending message: $e");
      print("Stacktrace: $stacktrace");
      showError('An error occurred while sending the message.');
      setState(() {
        messages.removeAt(0); 
      });
    }
  }


  void showError(String message) {
    print("Error: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() {
      isLoading = false;
    });
  }

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
              reverse: true, 
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
                          ? Color(0xFF5AA5B1) 
                          : Colors.white, 
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

  String _formatTimestamp(dynamic timestamp) {
    final seconds = timestamp['_seconds'];
    final dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}"; 
  }
}
