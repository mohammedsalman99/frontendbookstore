import 'dart:convert';
import 'package:http/http.dart' as http;

class LatestService {
  final String baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books';

  Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['books'] != null) {
          return data['books'];
        } else {
          throw Exception('Failed to fetch books');
        }
      } else {
        throw Exception('Failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching books: $e');
    }
  }
}
