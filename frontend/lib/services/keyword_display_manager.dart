import '../models/keyword_model.dart';

class KeywordDisplayManager {
  static const int displayLimit = 7;

  final List<KeywordModel> _fullList;
  late List<KeywordModel> _visible;
  late List<KeywordModel> _reserve;

  KeywordDisplayManager(List<KeywordModel> fullList) : _fullList = fullList {
    _visible = fullList.take(displayLimit).toList();
    _reserve = fullList.skip(displayLimit).toList();
  }

  List<KeywordModel> get visibleKeywords => List.unmodifiable(_visible);
  List<KeywordModel> get reserveKeywords => List.unmodifiable(_reserve);
  int get totalVisible => _visible.length;
  bool get hasReserve => _reserve.isNotEmpty;

  /// Removes the keyword at [index] from visible.
  /// If reserve is non-empty, inserts the next reserve keyword at the same index.
  /// If reserve is empty, the visible list shrinks by one.
  /// Returns the replacement keyword, or null if no replacement was available.
  KeywordModel? replaceKnown(int index) {
    RangeError.checkValidIndex(index, _visible);

    _visible.removeAt(index);

    if (_reserve.isNotEmpty) {
      final replacement = _reserve.removeAt(0);
      _visible.insert(index, replacement);
      return replacement;
    }

    return null;
  }
}
