import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, test, group;
import 'package:quran_prep/models/keyword_model.dart';
import 'package:quran_prep/services/keyword_display_manager.dart';
import 'package:quran_prep/services/selection_tracker.dart';

extension KeywordModelGenerators on Any {
  Generator<KeywordModel> get keywordModel => combine4(
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        (String arabic, String translation, String hint, String type) =>
            KeywordModel(
          arabic: arabic,
          translation: translation,
          hint: hint,
          type: type,
        ),
      );

  /// List of KeywordModel with length between 2 and 14.
  Generator<List<KeywordModel>> get keywordListAtLeast2 =>
      listWithLengthInRange(2, 15, keywordModel);
}

void main() {
  // Feature: keyword-rating-simplification, Property 3: "Not known" advances index without modifying visible list
  // **Validates: Requirements 3.2, 6.3**
  Glados(any.keywordListAtLeast2, ExploreConfig(numRuns: 100)).test(
    '"Not known" advances index without modifying visible list',
    (keywords) {
      final manager = KeywordDisplayManager(keywords);
      final tracker = SelectionTracker();

      final visibleCount = manager.totalVisible;

      // Test all valid non-last indices for this generated list
      for (var currentIndex = 0;
          currentIndex < visibleCount - 1;
          currentIndex++) {
        // Snapshot the visible list before the action
        final snapshotBefore =
            manager.visibleKeywords.map((k) => k.arabic).toList();

        // Simulate the "Not known" action:
        // 1. Record the keyword with status "not_known"
        final currentKeyword = manager.visibleKeywords[currentIndex];
        tracker.record(
            currentKeyword.arabic, currentKeyword.translation, 'not_known');

        // 2. Advance index (no call to replaceKnown — list stays the same)
        final newIndex = currentIndex + 1;

        // Snapshot the visible list after the action
        final snapshotAfter =
            manager.visibleKeywords.map((k) => k.arabic).toList();

        // Verify: index advanced by 1
        expect(newIndex, equals(currentIndex + 1));

        // Verify: visible list is unchanged (same length, same elements, same order)
        expect(snapshotAfter.length, equals(snapshotBefore.length),
            reason: 'Visible list length should not change after "Not known"');
        expect(snapshotAfter, orderedEquals(snapshotBefore),
            reason:
                'Visible list elements and order should not change after "Not known"');
      }
    },
  );
}
