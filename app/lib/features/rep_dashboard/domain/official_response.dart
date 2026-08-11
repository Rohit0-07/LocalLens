class OfficialResponse {
  final String id;
  final int issueId;
  final String representativeId;
  final String officialName;
  final String title;
  final String ward;
  final String message;
  final int? estimatedResolutionDays;
  final String? statusUpdate;
  final DateTime? createdAt;

  const OfficialResponse({
    required this.id,
    required this.issueId,
    required this.representativeId,
    required this.officialName,
    required this.title,
    required this.ward,
    required this.message,
    this.estimatedResolutionDays,
    this.statusUpdate,
    this.createdAt,
  });

  factory OfficialResponse.fromJson(Map<String, dynamic> json) {
    return OfficialResponse(
      id: json['id'] as String,
      issueId: json['issue_id'] as int,
      representativeId: json['representative_id'] as String,
      officialName: json['official_name'] as String,
      title: json['title'] as String,
      ward: json['ward'] as String,
      message: json['message'] as String,
      estimatedResolutionDays: json['estimated_resolution_days'] as int?,
      statusUpdate: json['status_update'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'issue_id': issueId,
    'representative_id': representativeId,
    'official_name': officialName,
    'title': title,
    'ward': ward,
    'message': message,
    'estimated_resolution_days': estimatedResolutionDays,
    'status_update': statusUpdate,
    'created_at': createdAt?.toIso8601String(),
  };
}
