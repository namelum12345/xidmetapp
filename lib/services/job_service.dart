import 'job_catalog_service.dart';

/// Firebase üzrə elanlar API-si — UI və digər servislər bunun vasitəsilə işləsin.
///
/// Hazırda real vaxtda sinxron [JobCatalogService] singleton-ına yönləndirir.
abstract final class JobService {
  static JobCatalogService get instance => JobCatalogService.instance;
}
