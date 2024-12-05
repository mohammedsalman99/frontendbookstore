import 'dart:convert';
import 'package:http/http.dart' as http;

class LatestService {
  final String baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/books';

  Future<List<dynamic>> fetchBooks() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));

      // Check if the response is successful
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);

          // Check if 'books' key exists and is a list
          if (data.containsKey('books') && data['books'] is List) {
            return data['books'];
          } else {
            throw Exception('Books data missing or invalid in response');
          }
        } catch (jsonError) {
          throw Exception('Error decoding JSON: $jsonError');
        }
      } else if (response.statusCode >= 500) {
        throw Exception('Server error: ${response.statusCode}');
      } else if (response.statusCode >= 400) {
        throw Exception('Client error: ${response.statusCode}');
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } on http.ClientException catch (clientError) {
      throw Exception('Network issue: $clientError');
    } on FormatException catch (formatError) {
      throw Exception('Invalid response format: $formatError');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
