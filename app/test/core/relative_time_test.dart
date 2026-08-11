import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/utils/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 8, 9, 12, 0, 0);

  test('seconds ago is just now', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(seconds: 30)), now: now),
      'just now',
    );
  });

  test('minutes ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
  });

  test('hours ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(hours: 3)), now: now),
      '3h ago',
    );
  });

  test('days ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 2)), now: now),
      '2d ago',
    );
  });

  test('weeks ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 14)), now: now),
      '2w ago',
    );
  });

  test('months ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 90)), now: now),
      '3mo ago',
    );
  });

  test('years ago', () {
    expect(
      formatRelativeTime(now.subtract(const Duration(days: 400)), now: now),
      '1y ago',
    );
  });

  test('future timestamps are clamped to just now', () {
    expect(
      formatRelativeTime(now.add(const Duration(minutes: 10)), now: now),
      'just now',
    );
  });
}
