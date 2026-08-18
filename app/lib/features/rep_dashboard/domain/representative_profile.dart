class RepresentativeProfile {
  final String id;
  final int userId;
  final String officialName;
  final String title;
  final String ward;
  final DateTime? verifiedAt;
  final int totalWardIssues;
  final int escalatedWardIssues;
  final int respondedWardIssues;
  final int pendingResponseWardIssues;
  final int resolvedWardIssues;
  final int inProgressWardIssues;
  final int acknowledgedWardIssues;
  final double responseRatePct;
  final double avgResponseTimeHours;

  const RepresentativeProfile({
    required this.id,
    required this.userId,
    required this.officialName,
    required this.title,
    required this.ward,
    this.verifiedAt,
    required this.totalWardIssues,
    required this.escalatedWardIssues,
    required this.respondedWardIssues,
    required this.pendingResponseWardIssues,
    this.resolvedWardIssues = 0,
    this.inProgressWardIssues = 0,
    this.acknowledgedWardIssues = 0,
    this.responseRatePct = 0.0,
    this.avgResponseTimeHours = 0.0,
  });

  factory RepresentativeProfile.fromJson(Map<String, dynamic> json) {
    return RepresentativeProfile(
      id: json['id'] as String,
      userId: json['user_id'] as int,
      officialName: json['official_name'] as String,
      title: json['title'] as String,
      ward: json['ward'] as String,
      verifiedAt: json['verified_at'] != null ? DateTime.parse(json['verified_at'] as String) : null,
      totalWardIssues: json['total_ward_issues'] as int? ?? 0,
      escalatedWardIssues: json['escalated_ward_issues'] as int? ?? 0,
      respondedWardIssues: json['responded_ward_issues'] as int? ?? 0,
      pendingResponseWardIssues: json['pending_response_ward_issues'] as int? ?? 0,
      resolvedWardIssues: (json['resolved_ward_issues'] as num?)?.toInt() ?? 0,
      inProgressWardIssues: (json['in_progress_ward_issues'] as num?)?.toInt() ?? 0,
      acknowledgedWardIssues: (json['acknowledged_ward_issues'] as num?)?.toInt() ?? 0,
      responseRatePct: (json['response_rate_pct'] as num?)?.toDouble() ?? 0.0,
      avgResponseTimeHours: (json['avg_response_time_hours'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'official_name': officialName,
    'title': title,
    'ward': ward,
    'verified_at': verifiedAt?.toIso8601String(),
    'total_ward_issues': totalWardIssues,
    'escalated_ward_issues': escalatedWardIssues,
    'responded_ward_issues': respondedWardIssues,
    'pending_response_ward_issues': pendingResponseWardIssues,
    'resolved_ward_issues': resolvedWardIssues,
    'in_progress_ward_issues': inProgressWardIssues,
    'acknowledged_ward_issues': acknowledgedWardIssues,
    'response_rate_pct': responseRatePct,
    'avg_response_time_hours': avgResponseTimeHours,
  };
}
