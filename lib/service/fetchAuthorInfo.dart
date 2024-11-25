import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthorService {
  Future<Map<String, dynamic>> fetchAuthorInfo(String authorId) async {
    final response = await http.get(Uri.parse(
        'https://readme-backend-zdiq.onrender.com/api/v1/authors/$authorId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['author'];
    } else {
      throw Exception('Failed to load author info');
    }
  }
}
