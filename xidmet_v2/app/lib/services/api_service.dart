import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kBaseUrl = 'https://xidmet.ecoguard.online';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  static const String baseUrl = _kBaseUrl;

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_json');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  String? get token => _token;

  Future<dynamic> get(String path) => _req('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _req('POST', path, body);
  Future<dynamic> put(String path, [Map<String, dynamic>? body]) => _req('PUT', path, body);
  Future<dynamic> delete(String path) => _req('DELETE', path);

  Future<dynamic> _req(String method, String path, [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('$_kBaseUrl$path');
    http.Response resp;
    try {
      switch (method) {
        case 'POST':
          resp = await http.post(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 15));
        case 'PUT':
          resp = await http.put(uri, headers: _headers, body: body != null ? jsonEncode(body) : null)
              .timeout(const Duration(seconds: 15));
        case 'DELETE':
          resp = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 15));
        default:
          resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      }
    } on SocketException catch (e) {
      throw ApiException(0, 'Server ilə əlaqə yoxdur ($e)');
    } on TimeoutException {
      throw const ApiException(0, 'Server cavab vermir (timeout)');
    } on HttpException catch (e) {
      throw ApiException(0, 'Şəbəkə xətası ($e)');
    } catch (e) {
      throw ApiException(0, 'Xəta: $e');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      if (resp.body.isEmpty) return null;
      return jsonDecode(utf8.decode(resp.bodyBytes));
    }

    String msg = 'Xəta baş verdi';
    try {
      final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
      msg = decoded['detail'] ?? msg;
    } catch (_) {}
    throw ApiException(resp.statusCode, msg);
  }
}
