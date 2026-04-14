/// Returns a human-readable relative date string for [date] compared to [now].
///
/// The optional [now] parameter defaults to `DateTime.now()` and enables
/// deterministic testing.
///
/// Mapping:
/// - 0 days → "Today"
/// - 1 day → "Yesterday"
/// - 2–6 days → "{n} days ago"
/// - 7–13 days → "1 week ago"
/// - 14+ days → "{n} weeks ago"
String formatRelativeDate(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();

  // Compute calendar day difference using date-only values.
  final dateDay = DateTime(date.year, date.month, date.day);
  final referenceDay = DateTime(reference.year, reference.month, reference.day);
  final daysDifference = referenceDay.difference(dateDay).inDays;

  if (daysDifference <= 0) return 'Today';
  if (daysDifference == 1) return 'Yesterday';
  if (daysDifference <= 6) return '$daysDifference days ago';
  if (daysDifference <= 13) return '1 week ago';

  final weeks = daysDifference ~/ 7;
  return '$weeks weeks ago';
}
