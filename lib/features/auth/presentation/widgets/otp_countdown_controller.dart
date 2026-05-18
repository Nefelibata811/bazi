import 'dart:async';

import 'package:flutter/foundation.dart';

/// Manages OTP / resend cooldown timer for auth forms.
class OtpCountdownController {
  OtpCountdownController();

  Timer? _timer;
  int remaining = 0;

  bool get isActive => remaining > 0;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  void start({
    int seconds = 60,
    required void Function(int remaining) onTick,
    required bool Function() mounted,
    VoidCallback? onComplete,
  }) {
    _timer?.cancel();
    remaining = seconds;
    onTick(remaining);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted()) {
        timer.cancel();
        return;
      }
      if (remaining <= 1) {
        timer.cancel();
        remaining = 0;
        onTick(0);
        onComplete?.call();
      } else {
        remaining--;
        onTick(remaining);
      }
    });
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    remaining = 0;
  }
}
