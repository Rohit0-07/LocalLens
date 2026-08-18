/// Clean, professional string formatters that eliminate raw snake_case
/// identifiers (`some_some_some`) across the app and turn them into Title Case / Human-Readable labels.
class StringFormatters {
  StringFormatters._();

  /// Converts snake_case, kebab-case, or concatenated keys into human-readable Title Case.
  /// Example: 'some_some_some' -> 'Some Some Some'
  /// Example: 'pending_quorum_verification' -> 'Pending Quorum Verification'
  static String humanize(String? text) {
    if (text == null || text.trim().isEmpty) return '';
    final cleaned = text.replaceAll(RegExp('[_-]+'), ' ').trim();
    final words = cleaned.split(RegExp(r'\s+'));
    return words.map((w) {
      if (w.isEmpty) return '';
      if (w.length == 1) return w.toUpperCase();
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Formats category codes into citizen-friendly display labels.
  static String formatCategory(String? category) {
    if (category == null || category.trim().isEmpty) return 'General';
    final normalized = category.trim().toLowerCase();
    switch (normalized) {
      case 'all':
        return 'All Categories';
      case 'road':
      case 'roads':
        return 'Roads & Potholes';
      case 'water':
      case 'water_supply':
        return 'Water Supply';
      case 'power':
      case 'electricity':
        return 'Power & Grid';
      case 'sanitation':
        return 'Sanitation';
      case 'sewage':
      case 'drainage':
        return 'Sewage & Drainage';
      case 'lighting':
      case 'streetlight':
        return 'Street Lighting';
      case 'waste':
      case 'garbage':
        return 'Waste Management';
      case 'traffic':
        return 'Traffic & Transit';
      default:
        return humanize(category);
    }
  }

  /// Formats issue and response statuses into clean human-readable badges.
  static String formatStatus(String? status) {
    if (status == null || status.trim().isEmpty) return 'Unacknowledged';
    final normalized = status.trim().toLowerCase();
    switch (normalized) {
      case 'unacknowledged':
      case 'open':
        return 'Unacknowledged';
      case 'under_review':
      case 'in_progress':
      case 'acknowledged':
        return 'Under Review';
      case 'pending_quorum':
      case 'pending_verification':
        return 'Pending Quorum';
      case 'escalated':
      case 'escalating':
        return 'Escalated';
      case 'resolved':
        return 'Resolved';
      case 'disputed':
        return 'Disputed';
      case 'rejected':
      case 'dismissed':
        return 'Dismissed';
      case 'needs_response':
        return 'Needs Response';
      default:
        return humanize(status);
    }
  }

  /// Formats ward slugs or raw codes into clean Title Case representation.
  static String formatWard(String? ward) {
    if (ward == null || ward.trim().isEmpty) return 'Ward';
    return humanize(ward);
  }
}
