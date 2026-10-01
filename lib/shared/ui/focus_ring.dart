import 'package:flutter/material.dart';

import 'design_tokens.dart';

final class FocusRing extends StatefulWidget {
  const FocusRing({
    required this.focusNode,
    required this.child,
    this.onKeyEvent,
    this.onFocusChange,
    this.canRequestFocus = true,
    this.borderRadius = ClockRhythmRadius.small,
    this.borderWidth = 3,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  final bool canRequestFocus;
  final double borderRadius;
  final double borderWidth;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

final class _FocusRingState extends State<FocusRing> {
  late bool _isFocused = widget.focusNode.hasFocus;

  @override
  void didUpdateWidget(FocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      canRequestFocus: widget.canRequestFocus,
      onKeyEvent: widget.onKeyEvent,
      onFocusChange: (bool hasFocus) {
        if (_isFocused != hasFocus) {
          setState(() {
            _isFocused = hasFocus;
          });
        }
        widget.onFocusChange?.call(hasFocus);
      },
      child: AnimatedContainer(
        duration: ClockRhythmMotion.accessibleDuration(
          context,
          ClockRhythmMotion.fast,
        ),
        foregroundDecoration: BoxDecoration(
          border: _isFocused
              ? Border.all(
                  color: Theme.of(context).focusColor,
                  width: widget.borderWidth,
                )
              : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      ),
    );
  }
}
