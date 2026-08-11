import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_store.dart';

class FlagOut {
  final int id;
  final int issueId;
  final int? reporterId;
  final String? anonId;
  final String category;
  final String? details;
  final String createdAt;

  FlagOut({
    required this.id,
    required this.issueId,
    this.reporterId,
    this.anonId,
    required this.category,
    this.details,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'issue_id': issueId,
        'reporter_id': reporterId,
        'anon_id': anonId,
        'category': category,
        'details': details,
        'created_at': createdAt,
      };

  factory FlagOut.fromJson(Map<String, dynamic> json) => FlagOut(
        id: json['id'] as int,
        issueId: json['issue_id'] as int,
        reporterId: json['reporter_id'] as int?,
        anonId: json['anon_id'] as String?,
        category: json['category'] as String,
        details: json['details'] as String?,
        createdAt: json['created_at'] as String,
      );
}

class FlagIssueNotifier extends FamilyAsyncNotifier<FlagOut?, int> {
  late int issueId;
  bool isGuestUser = false;
  bool submitCalled = false;
  String? lastCategory;
  String? lastDetails;

  @override
  Future<FlagOut?> build(int arg) async {
    issueId = arg;
    return null;
  }

  Future<bool> submitFlag({required String category, String? details}) async {
    submitCalled = true;
    lastCategory = category;
    lastDetails = details;
    if (isGuestUser) {
      return false;
    }
    await LocalStore.instance.addFlaggedIssueId(issueId);
    state = AsyncData(FlagOut(
      id: 1,
      issueId: issueId,
      category: category,
      details: details,
      createdAt: DateTime.now().toIso8601String(),
    ));
    return true;
  }
}

final flagIssueNotifierProvider = AsyncNotifierProviderFamily<
    FlagIssueNotifier, FlagOut?, int>(FlagIssueNotifier.new);
