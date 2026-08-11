import '../../feed/domain/issue.dart';
import 'ward_representative_out.dart';

class WardDetailOut {
  final String slug;
  final String name;
  final String code;
  final double centerLatitude;
  final double centerLongitude;
  final int totalIssues;
  final int activeIssues;
  final int escalatedIssues;
  final int resolvedIssues;
  final double resolutionRatePct;
  final List<String> topCategories;
  final WardRepresentativeOut? assignedRepresentative;
  final List<Issue> recentIssues;
  final DateTime? updatedAt;

  const WardDetailOut({
    required this.slug,
    required this.name,
    required this.code,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.totalIssues,
    required this.activeIssues,
    required this.escalatedIssues,
    required this.resolvedIssues,
    required this.resolutionRatePct,
    this.topCategories = const [],
    this.assignedRepresentative,
    this.recentIssues = const [],
    this.updatedAt,
  });

  factory WardDetailOut.fromJson(Map<String, dynamic> json) {
    return WardDetailOut(
      slug: json['slug'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
      totalIssues: (json['total_issues'] as num).toInt(),
      activeIssues: (json['active_issues'] as num).toInt(),
      escalatedIssues: (json['escalated_issues'] as num).toInt(),
      resolvedIssues: (json['resolved_issues'] as num).toInt(),
      resolutionRatePct: (json['resolution_rate_pct'] as num).toDouble(),
      topCategories: json['top_categories'] != null
          ? List<String>.from(json['top_categories'] as List)
          : const [],
      assignedRepresentative: json['assigned_representative'] != null
          ? WardRepresentativeOut.fromJson(json['assigned_representative'] as Map<String, dynamic>)
          : null,
      recentIssues: json['recent_issues'] != null
          ? (json['recent_issues'] as List)
              .map((i) => Issue.fromJson(i as Map<String, dynamic>))
              .toList()
          : const [],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'name': name,
      'code': code,
      'center_latitude': centerLatitude,
      'center_longitude': centerLongitude,
      'total_issues': totalIssues,
      'active_issues': activeIssues,
      'escalated_issues': escalatedIssues,
      'resolved_issues': resolvedIssues,
      'resolution_rate_pct': resolutionRatePct,
      'top_categories': topCategories,
      'assigned_representative': assignedRepresentative?.toJson(),
      'recent_issues': recentIssues.map((i) => i.toJson()).toList(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
