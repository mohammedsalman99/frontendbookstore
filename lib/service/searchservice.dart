import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchService {
  final String baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1/search/all';

  Future<Map<String, dynamic>> search(String query) async {
    try {
      // Construct the URL with query parameter
      final url = Uri.parse('$baseUrl?query=$query');

      // Make the GET request
      final response = await http.get(url);

      // Handle the response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Ensure the 'results' key exists
        if (data.containsKey('results')) {
          return data['results'] as Map<String, dynamic>;
        } else {
          throw Exception('Search failed: "results" key not found in response.');
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
