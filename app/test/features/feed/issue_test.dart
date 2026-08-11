import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/features/feed/domain/issue.dart';

void main() {
  test('fromJson maps snake_case keys', () {
    final issue = Issue.fromJson({
      'id': 7,
      'title': 'Deep pothole near the bus stop',
      'description': 'Three tires punctured',
      'category': 'road',
      'status': 'open',
      'latitude': 19.1136,
      'longitude': 72.8697,
      'is_anonymous': true,
      'reporter_label': 'Anonymous',
      'created_at': '2026-08-09T08:00:00Z',
    });

    expect(issue.id, 7);
    expect(issue.isAnonymous, isTrue);
    expect(issue.reporterLabel, 'Anonymous');
    expect(issue.createdAt, DateTime.utc(2026, 8, 9, 8));
  });

  test('isResolved reflects status', () {
    final open = Issue(
      id: 1,
      title: 't',
      description: '',
      category: 'road',
      status: 'open',
      latitude: 0,
      longitude: 0,
      isAnonymous: false,
      reporterLabel: 'x',
      createdAt: DateTime.utc(2026),
    );
    final resolved = open.copyWith(status: 'resolved');

    expect(open.isResolved, isFalse);
    expect(resolved.isResolved, isTrue);
  });
}
