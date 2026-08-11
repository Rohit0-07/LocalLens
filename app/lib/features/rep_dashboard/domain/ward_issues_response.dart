import '../../feed/domain/issue.dart';

class WardIssuesResponse {
  final List<Issue> items;
  final int total;

  const WardIssuesResponse({
    required this.items,
    required this.total,
  });

  factory WardIssuesResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List<dynamic>? ?? [];
    return WardIssuesResponse(
      items: list.map((e) => Issue.fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((e) => e.toJson()).toList(),
    'total': total,
  };
}
