import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl =
      'https://goldbarpe.com/backend'; // Update with actual URL

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  void _log(
    String method,
    String url,
    dynamic body,
    Map<String, String> headers,
    http.Response response,
  ) {
    if (kDebugMode) {
      debugPrint(
        '╔══════════════════════════════════════════════════════════════════════════',
      );
      debugPrint('║ 🚀 API REQUEST: $method');
      debugPrint('║ 🔗 URL: $url');
      debugPrint('║ 📥 HEADERS: $headers');
      if (body != null) debugPrint('║ 📦 BODY: ${jsonEncode(body)}');
      debugPrint(
        '╠══════════════════════════════════════════════════════════════════════════',
      );
      debugPrint('║ ✅ API RESPONSE (${response.statusCode})');
      debugPrint('║ 📄 CONTENT: ${response.body}');
      debugPrint(
        '╚══════════════════════════════════════════════════════════════════════════',
      );
    }
  }

  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await _getToken();
    final url = '$baseUrl$endpoint';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('DEBUG: Requesting GET $url');
    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      _log('GET', url, null, headers, response);
      return jsonDecode(response.body);
    } catch (e) {
      print('DEBUG: API Error on GET $url: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    final url = '$baseUrl$endpoint';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('DEBUG: Requesting POST $url with body: ${jsonEncode(body)}');
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      _log('POST', url, body, headers, response);
      return jsonDecode(response.body);
    } catch (e) {
      print('DEBUG: API Error on POST $url: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final token = await _getToken();
    final url = '$baseUrl$endpoint';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('DEBUG: Requesting PUT $url with body: ${jsonEncode(body)}');
    try {
      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      _log('PUT', url, body, headers, response);
      return jsonDecode(response.body);
    } catch (e) {
      print('DEBUG: API Error on PUT $url: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    final token = await _getToken();
    final url = '$baseUrl$endpoint';
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    print('DEBUG: Requesting DELETE $url');
    try {
      final response = await http.delete(Uri.parse(url), headers: headers);
      _log('DELETE', url, null, headers, response);
      return jsonDecode(response.body);
    } catch (e) {
      print('DEBUG: API Error on DELETE $url: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
