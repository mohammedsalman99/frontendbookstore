import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  final String baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/search/all';

  Future<Map<String, dynamic>> search(String query) async {
    try {
      final url = Uri.parse('$baseUrl?query=$query');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey('success') && data['success'] == true) {
          return data['results'];
        } else {
          throw Exception(
              'Search failed: ${data['message'] ?? 'Unknown error occurred.'}');
        }
      } else {
        throw Exception(
            'Failed with status code: ${response.statusCode}, reason: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error during search: $e');
    }
  }
}
