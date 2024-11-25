import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthorService {
  final String baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/authors';

  Future<List<dynamic>> fetchAuthors() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['authors'];
      } else {
        throw Exception('Failed to load authors');
      }
    } catch (e) {
      throw Exception('Error fetching authors: $e');
    }
  }
}
