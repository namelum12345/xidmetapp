import '../models/models.dart';
import 'api_service.dart';

class JobsService {
  JobsService._();
  static final instance = JobsService._();

  Future<List<JobModel>> getAll({
    String? category,
    String? q,
    double? lat,
    double? lng,
    double? radius,
    bool? isUrgent,
    String? status,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (radius != null) params['radius'] = radius.toString();
    if (isUrgent != null) params['is_urgent'] = isUrgent.toString();
    if (status != null) params['status'] = status;

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = '/jobs${query.isNotEmpty ? '?$query' : ''}';
    final data = await ApiService.instance.get(path) as List;
    return data.map((j) => JobModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<JobModel> get(String id) async {
    final data = await ApiService.instance.get('/jobs/$id');
    return JobModel.fromJson(data as Map<String, dynamic>);
  }

  Future<JobModel> create({
    required String title,
    required String category,
    String description = '',
    double budgetMin = 0,
    double budgetMax = 0,
    String address = '',
    double lat = 40.4093,
    double lng = 49.8671,
    bool isUrgent = false,
  }) async {
    final data = await ApiService.instance.post('/jobs', {
      'title': title,
      'description': description,
      'category': category,
      'budget_min': budgetMin,
      'budget_max': budgetMax,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_urgent': isUrgent,
    });
    return JobModel.fromJson(data as Map<String, dynamic>);
  }

  Future<JobModel> update(String id, Map<String, dynamic> body) async {
    final data = await ApiService.instance.put('/jobs/$id', body);
    return JobModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await ApiService.instance.delete('/jobs/$id');
  }

  Future<Map<String, dynamic>> applyToJob(
    String jobId, {
    String coverLetter = '',
  }) async {
    final data = await ApiService.instance.post('/jobs/$jobId/apply', {
      'cover_letter': coverLetter,
    });
    return data as Map<String, dynamic>;
  }

  Future<List<JobModel>> getMyJobs() async {
    final data = await ApiService.instance.get('/jobs/mine') as List;
    return data.map((j) => JobModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> getMyApplications() async {
    final data = await ApiService.instance.get('/jobs/worker/my-applications') as List;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> getJobApplications(String jobId) async {
    final data = await ApiService.instance.get('/jobs/$jobId/applications') as List;
    return data.map((item) => item as Map<String, dynamic>).toList();
  }

  Future<Map<String, dynamic>> updateApplicationStatus(
    String jobId,
    String applicationId,
    String status,
  ) async {
    final data = await ApiService.instance.put(
      '/jobs/$jobId/applications/$applicationId',
      {'status': status},
    );
    return data as Map<String, dynamic>;
  }

  Future<void> deleteApplication(String jobId, String applicationId) async {
    await ApiService.instance.delete('/jobs/$jobId/applications/$applicationId');
  }
}
