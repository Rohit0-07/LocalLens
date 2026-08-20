class WardRepresentativeOut {
  final String id;
  final int userId;
  final String ward;
  final String officialName;
  final String title;
  final String department;
  final String? handle;
  final bool isUnclaimed;
  final bool isVerified;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime? verifiedAt;
  final double? responseRatePercent;
  final double? avgResponseHours;
  final int? resolvedIssuesCount;
  final int? totalIssuesAssigned;

  const WardRepresentativeOut({
    this.id = '',
    this.userId = 0,
    this.ward = '',
    required this.officialName,
    required this.title,
    this.department = 'all',
    this.handle,
    this.isUnclaimed = false,
    this.isVerified = true,
    this.contactEmail,
    this.contactPhone,
    this.verifiedAt,
    this.responseRatePercent,
    this.avgResponseHours,
    this.resolvedIssuesCount,
    this.totalIssuesAssigned,
  });

  factory WardRepresentativeOut.fromJson(Map<String, dynamic> json) {
    return WardRepresentativeOut(
      id: json['id'] as String? ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      ward: json['ward'] as String? ?? '',
      officialName: json['official_name'] as String? ?? 'Official Representative',
      title: json['title'] as String? ?? 'Representative',
      department: json['department'] as String? ?? 'all',
      handle: json['handle'] as String?,
      isUnclaimed: json['is_unclaimed'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? (!(json['is_unclaimed'] as bool? ?? false)),
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      verifiedAt: json['verified_at'] != null
          ? DateTime.tryParse(json['verified_at'] as String)
          : null,
      responseRatePercent: (json['response_rate_percent'] as num?)?.toDouble(),
      avgResponseHours: (json['avg_response_hours'] as num?)?.toDouble(),
      resolvedIssuesCount: (json['resolved_issues_count'] as num?)?.toInt(),
      totalIssuesAssigned: (json['total_issues_assigned'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ward': ward,
      'official_name': officialName,
      'title': title,
      'department': department,
      'handle': handle,
      'is_unclaimed': isUnclaimed,
      'is_verified': isVerified,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'verified_at': verifiedAt?.toIso8601String(),
      'response_rate_percent': responseRatePercent,
      'avg_response_hours': avgResponseHours,
      'resolved_issues_count': resolvedIssuesCount,
      'total_issues_assigned': totalIssuesAssigned,
    };
  }
}
