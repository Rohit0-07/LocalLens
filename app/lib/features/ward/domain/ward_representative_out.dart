class WardRepresentativeOut {
  final String officialName;
  final String title;
  final DateTime? verifiedAt;

  const WardRepresentativeOut({
    required this.officialName,
    required this.title,
    this.verifiedAt,
  });

  factory WardRepresentativeOut.fromJson(Map<String, dynamic> json) {
    return WardRepresentativeOut(
      officialName: json['official_name'] as String,
      title: json['title'] as String,
      verifiedAt: json['verified_at'] != null
          ? DateTime.parse(json['verified_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'official_name': officialName,
      'title': title,
      'verified_at': verifiedAt?.toIso8601String(),
    };
  }
}
