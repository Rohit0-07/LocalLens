class WardRepresentativeOut {
  final String id;
  final int userId;
  final String ward;
  final String officialName;
  final String title;
  final DateTime? verifiedAt;

  const WardRepresentativeOut({
    this.id = '',
    this.userId = 0,
    this.ward = '',
    required this.officialName,
    required this.title,
    this.verifiedAt,
  });

  factory WardRepresentativeOut.fromJson(Map<String, dynamic> json) {
    return WardRepresentativeOut(
      id: json['id'] as String? ?? '',
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      ward: json['ward'] as String? ?? '',
      officialName: json['official_name'] as String,
      title: json['title'] as String,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ward': ward,
      'official_name': officialName,
      'title': title,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}
