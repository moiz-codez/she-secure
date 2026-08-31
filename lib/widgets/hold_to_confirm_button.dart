import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A press-and-hold control: fires [onConfirmed] once the pointer has been
/// held down continuously for [holdDuration], and resets to zero the
/// moment the pointer lifts early — a plain tap never fires it. Used for
/// the SOS arm button, the "hold to stop" button, and the silent
/// "I am safe" duress hold.
///
/// [builder] is rebuilt on every animation tick with the current hold
/// progress (0.0-1.0) so callers can paint a fill ring / swap a label.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.builder,
    required this.holdDuration,
    required this.onConfirmed,
    this.onReleasedEarly,
  });

  final Widget Function(BuildContext context, double progress) builder;
  final Duration holdDuration;
  final VoidCallback onConfirmed;

  /// Fired when the pointer lifts before [holdDuration] elapses — a plain
  /// tap counts. Only the "I am safe" check-in button uses this (a quick
  /// tap confirms safety; only a sustained hold signals duress); the SOS
  /// arm/stop buttons leave this null so a bare tap does nothing.
  final VoidCallback? onReleasedEarly;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onConfirmed();
          _controller.reset();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _start() {
    if (_controller.value == 0) _controller.forward();
  }

  void _cancel() {
    if (_controller.status != AnimationStatus.forward) return;
    _controller.reset();
    widget.onReleasedEarly?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(context, _controller.value),
      ),
    );
  }
}

/// A hard-edged circular fill ring matching the design canvas's
/// `conic-gradient(accent {progress}%, faint 0)` ring — Flutter's native
/// [SweepGradient] is the direct equivalent of a CSS conic-gradient.
class HoldProgressRing extends StatelessWidget {
  const HoldProgressRing({
    super.key,
    required this.progress,
    required this.diameter,
    required this.filledColor,
    required this.emptyColor,
  });

  final double progress;
  final double diameter;
  final Color filledColor;
  final Color emptyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: progress > 0
            ? SweepGradient(
                startAngle: -math.pi / 2,
                endAngle: 3 * math.pi / 2,
                colors: [filledColor, filledColor, emptyColor, emptyColor],
                stops: [0, progress, progress, 1],
              )
            : null,
        color: progress > 0 ? null : emptyColor,
      ),
    );
  }
}
