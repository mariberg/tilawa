import 'dart:async';

class PreparingMessageController {
  static const List<String> messages = [
    'Analysing the passage…',
    'Identifying key vocabulary for your level…',
    'Ranking keywords by importance…',
    'Almost ready…',
  ];

  static const Duration interval = Duration(milliseconds: 2500);

  final void Function()? onChanged;
  Timer? _timer;
  int _currentIndex = 0;

  PreparingMessageController({this.onChanged});

  int get currentIndex => _currentIndex;
  String get currentMessage => messages[_currentIndex];
  bool get isComplete => _currentIndex >= messages.length - 1;

  /// Starts cycling. Resets index to 0 and begins a periodic timer.
  void start() {
    reset();
    _timer = Timer.periodic(interval, (_) => advance());
  }

  /// Advances to the next message. Cancels timer when last message is reached.
  void advance() {
    if (isComplete) return;
    _currentIndex++;
    if (isComplete) {
      _timer?.cancel();
      _timer = null;
    }
    onChanged?.call();
  }

  /// Cancels the timer and resets the index to 0.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _currentIndex = 0;
  }

  /// Alias for reset — used in widget dispose.
  void dispose() => reset();
}
