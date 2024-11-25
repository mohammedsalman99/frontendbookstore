import 'dart:convert';
import 'package:http/http.dart' as http;

class BookService {
  Future<List<dynamic>> fetchAuthorBooks(String authorId) async {
    final response = await http.get(Uri.parse(
        'https://readme-backend-zdiq.onrender.com/api/v1/books?authorId=$authorId'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return jsonData['books'];
    } else {
      throw Exception('Failed to load books');
    }
  }
}
