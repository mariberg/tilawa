/// Parses a pages string into (start, end, span).
///
/// Accepts formats: "Pages {start}–{end}", "Pages {start}", "{start}-{end}", "{start}".
/// Returns null if the string cannot be parsed.
({int start, int end, int span})? parsePageRange(String pages) {
  // Strip optional "Pages " prefix (case-sensitive, as API returns it this way).
  final stripped = pages.startsWith('Pages ') ? pages.substring(6) : pages;
  final trimmed = stripped.trim();
  if (trimmed.isEmpty) return null;

  // Try range pattern first: digits, optional whitespace, dash or en-dash, optional whitespace, digits.
  final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
  if (rangeMatch != null) {
    final start = int.parse(rangeMatch.group(1)!);
    final end = int.parse(rangeMatch.group(2)!);
    return (start: start, end: end, span: end - start + 1);
  }

  // Try single page pattern.
  final singleMatch = RegExp(r'^(\d+)$').firstMatch(trimmed);
  if (singleMatch != null) {
    final page = int.parse(singleMatch.group(1)!);
    return (start: page, end: page, span: 1);
  }

  return null;
}

/// Computes the next contiguous page range string.
///
/// Given start, end, span: returns "{end+1}-{end+span}" or "{end+1}" if span == 1.
String nextPageRange(int start, int end, int span) {
  final nextStart = end + 1;
  final nextEnd = end + span;
  if (span == 1) return '$nextStart';
  return '$nextStart-$nextEnd';
}

/// Formats a parsed range back to a string.
///
/// Returns "{start}-{end}" or "{start}" when start == end.
String formatPageRange(int start, int end) {
  if (start == end) return '$start';
  return '$start-$end';
}
