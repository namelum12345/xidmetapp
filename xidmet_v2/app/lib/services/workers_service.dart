import '../models/models.dart';
import 'api_service.dart';

class WorkersService {
  WorkersService._();
  static final WorkersService instance = WorkersService._();

  Future<List<WorkerModel>> getAll() async {
    final resp = await ApiService.instance.get('/workers');
    return (resp as List).map((w) => WorkerModel.fromJson(w)).toList();
  }

  Future<WorkerModel> getById(String id) async {
    final resp = await ApiService.instance.get('/workers/$id');
    return WorkerModel.fromJson(resp);
  }

  Future<WorkerModel> getMyProfile() async {
    final resp = await ApiService.instance.get('/workers/me');
    return WorkerModel.fromJson(resp);
  }

  Future<void> updateMyProfile(Map<String, dynamic> data) async {
    await ApiService.instance.put('/workers/me', data);
  }

  Future<List<ReviewModel>> getReviews(String workerId) async {
    final resp = await ApiService.instance.get('/workers/$workerId/reviews');
    return (resp as List).map((r) => ReviewModel.fromJson(r)).toList();
  }

  Future<void> addReview(String workerId, {required double rating, String comment = '', String? jobId}) async {
    await ApiService.instance.post('/workers/$workerId/reviews', {
      'rating': rating,
      'comment': comment,
      if (jobId != null) 'job_id': jobId,
    });
  }
}
