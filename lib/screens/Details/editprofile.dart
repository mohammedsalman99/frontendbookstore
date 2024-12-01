import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  final String? fullName;
  final String? gender;
  final String? phoneNumber;
  final String? email;
  final String? profilePicture;
  final String userId; // User ID for backend identification

  EditProfileScreen({
    required this.fullName,
    required this.gender,
    required this.phoneNumber,
    required this.email,
    required this.profilePicture,
    required this.userId,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String? _selectedGender;
  late String _profilePictureUrl;
  File? _imageFile;
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
    _emailController = TextEditingController(text: widget.email);
    _passwordController = TextEditingController();

    // Ensure the gender matches one of the dropdown values
    _selectedGender = widget.gender?.toLowerCase() ?? 'not specified'; // Convert to lowercase for consistency
    _profilePictureUrl = widget.profilePicture ?? '';
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token == null) {
          throw Exception('Authentication token not found. Please log in again.');
        }

        print('Token: $token');

        final uri = Uri.parse('https://readme-backend-zdiq.onrender.com/api/v1/users/profile');
        final request = http.MultipartRequest('PUT', uri)
          ..fields['fullName'] = _fullNameController.text
          ..fields['phoneNumber'] = _phoneNumberController.text
          ..fields['gender'] = _selectedGender ?? 'not specified'
          ..headers['Authorization'] = 'Bearer $token';

        print('Request fields: ${request.fields}');

        if (_imageFile != null) {
          print('Adding image file: ${_imageFile!.path}');
          request.files.add(
            await http.MultipartFile.fromPath(
              'profilePicture',
              _imageFile!.path,
              contentType: MediaType('image', 'jpeg'), // Set MIME type explicitly
            ),
          );
        } else {
          print('No image file selected.');
        }

        final response = await request.send();
        print('Response status: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        print('Response body: $responseBody');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(responseBody);
          if (responseData['success'] == true) {
            setState(() {
              _profilePictureUrl = responseData['user']['profilePicture'] ?? '';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Profile updated successfully!')),
            );
          } else {
            print('Backend error: ${responseData['message']}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update profile: ${responseData['message']}')),
            );
          }
        } else if (response.statusCode == 401) {
          print('Authorization error: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unauthorized. Please log in again.')),
          );
        } else {
          print('HTTP error: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.statusCode}')),
          );
        }
      } catch (error) {
        print('Exception occurred: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  /// Pick image using image picker
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// Show dialog to choose between camera and gallery
  void _changeProfilePicture() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Change Profile Picture"),
          content: const Text("Choose an option to update your profile picture."),
          actions: [
            TextButton(
              child: const Text("Camera"),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            TextButton(
              child: const Text("Gallery"),
              onPressed: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              GestureDetector(
                onTap: _changeProfilePicture,
                child: CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) // Show picked image
                      : (_profilePictureUrl.startsWith('http')
                      ? NetworkImage(_profilePictureUrl)
                      : const AssetImage('assets/images/user_placeholder.png')) as ImageProvider,
                ),
              ),
              const SizedBox(height: 20),

              // Full Name Field
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: "Full Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your full name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your email";
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return "Please enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone Number Field
              TextFormField(
                controller: _phoneNumberController,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your phone number";
                  }
                  if (!RegExp(r'^\+\d{10,15}$').hasMatch(value)) {
                    return "Please enter a valid phone number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender, // Ensure this value exists in the items array
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                items: ['male', 'female', 'not specified']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender[0].toUpperCase() + gender.substring(1)), // Capitalize for display
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile, // Disable button if loading
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
