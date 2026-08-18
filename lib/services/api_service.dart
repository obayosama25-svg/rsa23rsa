import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'session_manager.dart';

class ApiService {
  // ─── إعدادات السيرفر (Hostinger VPS) ──────────────────────
  static const String _serverHost = '2.24.108.101';
  static const int _serverPort = 5000;

  static String get baseUrl {
    // للتطوير المحلي: استخدم localhost
    if (kIsWeb && kDebugMode) return 'http://localhost:$_serverPort/api';
    // للإنتاج (ويب وموبايل): استخدم IP السيرفر على المنفذ 5000
    return 'http://$_serverHost:$_serverPort/api';
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
    ).timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[API] POST $endpoint');
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[API] PUT $endpoint');
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));
  }
}
