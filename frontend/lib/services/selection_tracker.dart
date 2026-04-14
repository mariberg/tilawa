import '../models/keyword_selection_record.dart';

class SelectionTracker {
  final Map<String, _TrackerEntry> _records = {};

  void record(String arabic, String translation, String status) {
    _records[arabic] = _TrackerEntry(translation: translation, status: status);
  }

  List<KeywordSelectionRecord> getRecords() {
    return _records.entries
        .map((e) => KeywordSelectionRecord(
              arabic: e.key,
              translation: e.value.translation,
              status: e.value.status,
            ))
        .toList();
  }

  int get count => _records.length;

  void reset() {
    _records.clear();
  }
}

class _TrackerEntry {
  final String translation;
  final String status;
  const _TrackerEntry({required this.translation, required this.status});
}
