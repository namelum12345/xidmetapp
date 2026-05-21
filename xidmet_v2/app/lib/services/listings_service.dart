import '../models/models.dart';
import 'api_service.dart';

class ListingsService {
  ListingsService._();
  static final instance = ListingsService._();

  Future<List<ListingModel>> getAll({
    String? category,
    String? q,
    double? lat,
    double? lng,
    double? radius,
    bool? isUrgent,
    bool? homeService,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (q != null && q.isNotEmpty) params['q'] = q;
    if (lat != null) params['lat'] = lat.toString();
    if (lng != null) params['lng'] = lng.toString();
    if (radius != null) params['radius'] = radius.toString();
    if (isUrgent != null) params['is_urgent'] = isUrgent.toString();
    if (homeService != null) params['home_service'] = homeService.toString();

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final path = '/listings${query.isNotEmpty ? '?$query' : ''}';
    final data = await ApiService.instance.get(path) as List;
    return data.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ListingModel> get(String id) async {
    final data = await ApiService.instance.get('/listings/$id');
    return ListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<List<ListingModel>> getMyListings() async {
    final data = await ApiService.instance.get('/listings/my') as List;
    return data.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ListingModel>> getFavorites() async {
    final data = await ApiService.instance.get('/listings/favorites') as List;
    return data.map((j) => ListingModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<ListingModel> create({
    required String title,
    required String category,
    String description = '',
    List<String> images = const [],
    double minPrice = 0,
    double maxPrice = 0,
    String address = '',
    double lat = 40.4093,
    double lng = 49.8671,
    String workHours = '09:00-18:00',
    bool isUrgent = false,
    bool homeService = false,
    String contactPhone = '',
  }) async {
    final data = await ApiService.instance.post('/listings', {
      'title': title,
      'category': category,
      'description': description,
      'images': images,
      'min_price': minPrice,
      'max_price': maxPrice,
      'address': address,
      'lat': lat,
      'lng': lng,
      'work_hours': workHours,
      'is_urgent': isUrgent,
      'home_service': homeService,
      'contact_phone': contactPhone,
    });
    return ListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<ListingModel> update(String id, Map<String, dynamic> body) async {
    final data = await ApiService.instance.put('/listings/$id', body);
    return ListingModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await ApiService.instance.delete('/listings/$id');
  }

  Future<bool> toggleFavorite(String id) async {
    final data = await ApiService.instance.post('/listings/$id/favorite');
    return (data as Map<String, dynamic>)['is_favorite'] as bool;
  }

  Future<List<ReviewModel>> getReviews(String listingId) async {
    final data = await ApiService.instance.get('/listings/$listingId/reviews') as List;
    return data.map((j) => ReviewModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> addReview(String listingId, {required double rating, String comment = ''}) async {
    await ApiService.instance.post('/listings/$listingId/reviews', {
      'rating': rating,
      'comment': comment,
    });
  }
}
