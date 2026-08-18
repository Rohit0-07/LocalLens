import 'package:flutter_test/flutter_test.dart';
import 'package:local_lens/core/utils/string_formatters.dart';

void main() {
  group('StringFormatters Unit Tests', () {
    test('humanize formats snake_case and kebab-case into clean Title Case', () {
      expect(StringFormatters.humanize('some_some_some'), equals('Some Some Some'));
      expect(StringFormatters.humanize('pending_quorum_verification'), equals('Pending Quorum Verification'));
      expect(StringFormatters.humanize('traffic_signal_outage'), equals('Traffic Signal Outage'));
      expect(StringFormatters.humanize('ward-45-urban-central'), equals('Ward 45 Urban Central'));
      expect(StringFormatters.humanize(null), equals(''));
      expect(StringFormatters.humanize(''), equals(''));
    });

    test('formatCategory returns citizen-friendly display names', () {
      expect(StringFormatters.formatCategory('road'), equals('Roads & Potholes'));
      expect(StringFormatters.formatCategory('water'), equals('Water Supply'));
      expect(StringFormatters.formatCategory('sanitation'), equals('Sanitation'));
      expect(StringFormatters.formatCategory('power'), equals('Power & Grid'));
      expect(StringFormatters.formatCategory('lighting'), equals('Street Lighting'));
      expect(StringFormatters.formatCategory('waste'), equals('Waste Management'));
      expect(StringFormatters.formatCategory('custom_category_type'), equals('Custom Category Type'));
    });

    test('formatStatus returns clean human-readable statuses without underscores', () {
      expect(StringFormatters.formatStatus('unacknowledged'), equals('Unacknowledged'));
      expect(StringFormatters.formatStatus('under_review'), equals('Under Review'));
      expect(StringFormatters.formatStatus('in_progress'), equals('Under Review'));
      expect(StringFormatters.formatStatus('pending_quorum'), equals('Pending Quorum'));
      expect(StringFormatters.formatStatus('resolved'), equals('Resolved'));
      expect(StringFormatters.formatStatus('needs_response'), equals('Needs Response'));
    });

    test('formatWard returns clean Title Case representation', () {
      expect(StringFormatters.formatWard('ward_45_urban_central'), equals('Ward 45 Urban Central'));
      expect(StringFormatters.formatWard('ward-12-metro'), equals('Ward 12 Metro'));
    });
  });
}
