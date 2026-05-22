import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  UserModel? _user;
  bool _loading = true;

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  Future<void> init() async {
    await ApiService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_json');
    if (raw != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(raw));
      } catch (_) {}
    }
    _loading = false;
    notifyListeners();

    if (_user != null) {
      try {
        await refreshProfile();
      } catch (_) {}
    }
  }

  Future<String> login(String email, String password) async {
    final resp = await ApiService.instance.post('/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    await ApiService.instance.setToken(resp['token'] as String);
    await _saveUser();
    notifyListeners();
    return _user!.role;
  }

  Future<String> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String password,
    required String role,
    List<String> categories = const [],
    double lat = 40.4093,
    double lng = 49.8671,
    String address = '',
  }) async {
    final resp = await ApiService.instance.post('/auth/register', {
      'name': name,
      'surname': surname,
      'email': email.trim(),
      'phone': phone,
      'password': password,
      'role': role,
      'categories': categories,
      'lat': lat,
      'lng': lng,
      'address': address,
    });
    await ApiService.instance.setToken(resp['token'] as String);
    await _saveUser();
    notifyListeners();
    return _user!.role;
  }

  Future<void> signOut() async {
    _user = null;
    await ApiService.instance.clearToken();
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final resp = await ApiService.instance.get('/auth/me');
    _user = UserModel.fromJson(resp as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', jsonEncode(resp));
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final resp = await ApiService.instance.put('/users/me', data);
    _user = UserModel.fromJson(resp as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', jsonEncode(resp));
    notifyListeners();
  }

  Future<void> changePassword(String oldPass, String newPass) async {
    await ApiService.instance.post('/users/me/change-password', {
      'old_password': oldPass,
      'new_password': newPass,
    });
  }

  Future<void> _saveUser() async {
    final resp = await ApiService.instance.get('/auth/me');
    _user = UserModel.fromJson(resp as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_json', jsonEncode(resp));
  }
}
