import 'dart:async';

import 'package:flutter/material.dart';

import 'formatted_ai_text.dart';

/// Reveals [text] character-by-character at a steady pace.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charInterval = const Duration(milliseconds: 42),
    this.animate = true,
  });

  final String text;
  final TextStyle? style;
  final Duration charInterval;

  /// When false, show full text immediately (restored history).
  final bool animate;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  int _visibleLength = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _applyTextChange(reset: true);
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text == oldWidget.text &&
        widget.animate == oldWidget.animate) {
      return;
    }
    _applyTextChange(reset: widget.text.length < _visibleLength);
  }

  void _applyTextChange({required bool reset}) {
    _timer?.cancel();
    _timer = null;

    if (!widget.animate) {
      setState(() => _visibleLength = widget.text.length);
      return;
    }

    if (reset) {
      _visibleLength = 0;
    } else {
      _visibleLength = _visibleLength.clamp(0, widget.text.length);
    }

    if (widget.text.isEmpty) {
      setState(() => _visibleLength = 0);
      return;
    }

    _timer = Timer.periodic(widget.charInterval, (_) {
      if (!mounted) return;
      if (_visibleLength >= widget.text.length) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      setState(() => _visibleLength += 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final len = _visibleLength.clamp(0, widget.text.length);
    final visible = widget.text.substring(0, len);
    return FormattedAiText(text: visible, style: widget.style);
  }
}
