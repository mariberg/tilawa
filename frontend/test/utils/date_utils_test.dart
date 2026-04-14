import 'package:flutter_test/flutter_test.dart';
import 'package:quran_prep/utils/date_utils.dart';

void main() {
  group('formatRelativeDate', () {
    final now = DateTime(2025, 7, 10, 14, 30);

    test('returns "Today" for the same day', () {
      final date = DateTime(2025, 7, 10, 8, 0);
      expect(formatRelativeDate(date, now: now), 'Today');
    });

    test('returns "Today" when date equals now exactly', () {
      expect(formatRelativeDate(now, now: now), 'Today');
    });

    test('returns "Today" when date is in the future', () {
      final futureDate = DateTime(2025, 7, 12);
      expect(formatRelativeDate(futureDate, now: now), 'Today');
    });

    test('returns "Yesterday" for 1 day ago', () {
      final date = DateTime(2025, 7, 9, 23, 59);
      expect(formatRelativeDate(date, now: now), 'Yesterday');
    });

    test('returns "{n} days ago" for 2–6 days', () {
      expect(formatRelativeDate(DateTime(2025, 7, 8), now: now), '2 days ago');
      expect(formatRelativeDate(DateTime(2025, 7, 4), now: now), '6 days ago');
    });

    test('returns "1 week ago" for 7–13 days', () {
      expect(formatRelativeDate(DateTime(2025, 7, 3), now: now), '1 week ago');
      expect(
          formatRelativeDate(DateTime(2025, 6, 27), now: now), '1 week ago');
    });

    test('returns "{n} weeks ago" for 14+ days', () {
      expect(
          formatRelativeDate(DateTime(2025, 6, 26), now: now), '2 weeks ago');
      expect(
          formatRelativeDate(DateTime(2025, 6, 10), now: now), '4 weeks ago');
    });

    test('handles month boundaries correctly', () {
      final endOfMonth = DateTime(2025, 8, 1);
      final startOfPrevMonth = DateTime(2025, 7, 1);
      // 31 days difference → 31 ~/ 7 = 4 weeks
      expect(
          formatRelativeDate(startOfPrevMonth, now: endOfMonth), '4 weeks ago');
    });

    test('handles year boundaries correctly', () {
      final jan1 = DateTime(2026, 1, 1);
      final dec31 = DateTime(2025, 12, 31);
      expect(formatRelativeDate(dec31, now: jan1), 'Yesterday');
    });
  });
}
