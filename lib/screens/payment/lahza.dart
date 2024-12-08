import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LahzaService {
  static const String _baseUrl = 'https://readme-backend-zdiq.onrender.com/api/v1';

  static Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _buildHeaders() async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("No authentication token found. Please log in.");
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<List<dynamic>> fetchPlans() async {
    const endpoint = '/subscription-plans/visible';
    final url = '$_baseUrl$endpoint';

    try {
      final headers = await _buildHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['plans']; 
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } catch (e) {
      throw Exception('Error fetching plans: $e');
    }
  }

  static Future<Map<String, dynamic>> subscribeToPlan(String planId) async {
    const endpoint = '/subscriptions//subscribe';
    final url = '$_baseUrl$endpoint';

    try {
      final headers = await _buildHeaders();
      final body = jsonEncode({'planId': planId});

      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } catch (e) {
      throw Exception('Error subscribing to plan: $e');
    }
  }
  static Future<Map<String, dynamic>> checkTransactionStatus(String transactionId) async {
    final endpoint = '/transactions/$transactionId';
    final url = '$_baseUrl$endpoint';

    try {
      final headers = await _buildHeaders();
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } catch (e) {
      throw Exception('Error checking transaction status: $e');
    }
  }

  static Future<Map<String, dynamic>> createTransaction(String planId, String paymentMethod) async {
    const endpoint = '/transactions';
    final url = '$_baseUrl$endpoint';

    try {
      final headers = await _buildHeaders();
      final body = jsonEncode({
        'planId': planId,
        'paymentMethod': paymentMethod, 
      });

      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(_extractErrorMessage(response));
      }
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  static String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'An unexpected error occurred.';
    } catch (_) {
      return 'An unexpected error occurred. Status code: ${response.statusCode}';
    }
  }
}
