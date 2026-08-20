import 'ward_summary_out.dart';

class WardListResponse {
  final List<WardSummaryOut> items;
  final int total;
  final int limit;
  final int offset;

  const WardListResponse({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  List<WardSummaryOut> get wards => items;

  factory WardListResponse.fromJson(Map<String, dynamic> json) {
    return WardListResponse(
      items: json['items'] != null
          ? (json['items'] as List)
              .map((i) => WardSummaryOut.fromJson(i as Map<String, dynamic>))
              .toList()
          : const [],
      total: (json['total'] as num).toInt(),
      limit: (json['limit'] as num).toInt(),
      offset: (json['offset'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
      'limit': limit,
      'offset': offset,
    };
  }
}
