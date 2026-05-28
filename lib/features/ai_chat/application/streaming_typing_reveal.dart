// 文件：流式typingreveal
//
// 路径：`lib/features/ai_chat/application/streaming_typing_reveal.dart`。
//
import 'dart:async';

/// Reveals streamed text one character at a fixed pace (never batch-jumps).
class StreamingTypingReveal {
  StreamingTypingReveal({
    this.charInterval = const Duration(milliseconds: 20),
  });

  final Duration charInterval;

  String _target = '';
  String _shown = '';
  Timer? _timer;
  void Function(String visible)? onTick;

  String get target => _target;
  String get shown => _shown;
  bool get isCaughtUp => _shown.length >= _target.length;

  void reset() {
    _timer?.cancel();
    _timer = null;
    _target = '';
    _shown = '';
  }

  // 释放监听器与控制器资源。
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void append(String chunk) {
    if (chunk.isEmpty) return;
    _target += chunk;
    _startTimer();
  }

  void _startTimer() {
    if (_timer != null) return;
    _timer = Timer.periodic(charInterval, (_) {
      if (_shown.length < _target.length) {
        _shown = _target.substring(0, _shown.length + 1);
        onTick?.call(_shown);
      } else {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  Future<void> waitUntilCaughtUp() async {
    while (!isCaughtUp) {
      await Future.delayed(charInterval);
    }
  }
}
