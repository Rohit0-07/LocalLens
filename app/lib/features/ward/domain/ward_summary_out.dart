class WardSummaryOut {
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

  const WardSummaryOut({
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
  });

  factory WardSummaryOut.fromJson(Map<String, dynamic> json) {
    return WardSummaryOut(
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
    };
  }
}
