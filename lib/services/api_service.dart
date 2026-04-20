import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _tokenKey = 'access_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _getHeaders({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  static Future<http.Response> get(String url, {bool withAuth = true}) async {
    final headers = await _getHeaders(withAuth: withAuth);
    return await http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    final headers = await _getHeaders(withAuth: withAuth);
    return await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body, {bool withAuth = true}) async {
    final headers = await _getHeaders(withAuth: withAuth);
    return await http.put(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static Future<http.Response> delete(String url, {bool withAuth = true}) async {
    final headers = await _getHeaders(withAuth: withAuth);
    return await http.delete(Uri.parse(url), headers: headers);
  }
}
