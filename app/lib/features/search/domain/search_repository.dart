import '../../feed/domain/issue.dart';

abstract interface class SearchRepository {
  Future<List<Issue>> search({
    required String query,
    double? latitude,
    double? longitude,
    String? status,
    List<String> categories = const <String>[],
    double? radiusKm,
    DateTime? createdAfter,
    DateTime? createdBefore,
    String? ward,
  });
}