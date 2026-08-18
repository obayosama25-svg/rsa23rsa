import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'session_manager.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:5000/api';
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = SessionManager().token;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String endpoint) async {
    debugPrint('[API] GET $endpoint');
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[API] POST $endpoint');
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[API] PUT $endpoint');
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
  }
}
