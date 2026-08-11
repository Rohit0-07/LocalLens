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
  };
}
