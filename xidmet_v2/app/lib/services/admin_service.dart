import '../models/models.dart';
import 'api_service.dart';

class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  Future<List<UserModel>> getUsers({String q = ''}) async {
    var path = '/admin/users';
    if (q.isNotEmpty) path += '?q=${Uri.encodeComponent(q)}';
    final resp = await ApiService.instance.get(path);
    return (resp as List).map((u) => UserModel.fromJson(u)).toList();
  }

  Future<List<UserModel>> getWorkers() async {
    final resp = await ApiService.instance.get('/admin/workers');
    return (resp as List).map((u) => UserModel.fromJson(u)).toList();
  }

  Future<List<ListingModel>> getListings() async {
    final resp = await ApiService.instance.get('/admin/listings');
    return (resp as List).map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getChats() async {
    final resp = await ApiService.instance.get('/admin/chats');
    return List<Map<String, dynamic>>.from(resp as List);
  }

  Future<bool> toggleBlock(String uid) async {
    final resp = await ApiService.instance.post('/admin/users/$uid/block');
    return resp['blocked'] as bool;
  }

  Future<void> deleteUser(String uid) async {
    await ApiService.instance.delete('/admin/users/$uid');
  }

  Future<void> deleteListing(String id) async {
    await ApiService.instance.delete('/admin/listings/$id');
  }

  Future<Map<String, int>> getStats() async {
    final resp = await ApiService.instance.get('/admin/stats');
    return Map<String, int>.from(
      (resp as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Future<UserModel> createAdmin({
    required String name,
    required String surname,
    required String email,
    String password = 'admin123',
  }) async {
    final resp = await ApiService.instance.post('/admin/create-admin', {
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
    });
    return UserModel.fromJson(resp as Map<String, dynamic>);
  }

  Future<void> changeRole(String uid, String role) async {
    await ApiService.instance.put('/admin/users/$uid/role?role=$role');
  }

  Future<List<Map<String, dynamic>>> getAuditLogs() async {
    final resp = await ApiService.instance.get('/admin/audit-logs');
    return List<Map<String, dynamic>>.from(resp as List);
  }
}
