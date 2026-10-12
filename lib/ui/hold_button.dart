import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../capture/capture.dart';
import '../theme.dart';

/// The big ink button. Press and hold to talk, let go to sort.
///
/// Two soft rings around it grow with your voice; a thin arc fills up over
/// the 30 seconds.
class HoldButton extends StatefulWidget {
  const HoldButton({super.key, required this.capture, this.size = 96});

  final CaptureController capture;
  final double size;

  @override
  State<HoldButton> createState() => _HoldButtonState();
}

class _HoldButtonState extends State<HoldButton>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _down = false;

  @override
  void initState() {
    super.initState();
    widget.capture.addListener(_changed);
  }

  @override
  void dispose() {
    widget.capture.removeListener(_changed);
    _pulse.dispose();
    super.dispose();
  }

  void _changed() {
    final working = widget.capture.phase == Phase.working;
    if (working && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!working && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
    setState(() {});
  }

  void _press() {
    if (widget.capture.busy) return;
    setState(() => _down = true);
    widget.capture.start();
  }

  void _release() {
    if (!_down) return;
    setState(() => _down = false);
    widget.capture.finish();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final c = widget.capture;
    final listening = c.phase == Phase.listening;
    final working = c.phase == Phase.working;
    final size = widget.size;
    // Room for the rings to grow while recording; snug when idle.
    final outer = size + (listening || working ? 76 : 36);

    // Screen readers can't hold, so for them a tap starts and a second tap
    // stops.
    return Semantics(
      button: true,
      label: listening
          ? 'Recording. Tap to stop and sort.'
          : 'Record a brain dump',
      onTap: working
          ? null
          : listening
          ? c.finish
          : c.start,
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => _press(),
        onPointerUp: (_) => _release(),
        onPointerCancel: (_) => _release(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: outer,
          height: outer,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              final level = listening ? c.level : 0.0;
              final breathe = working ? _pulse.value : 0.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 2; i >= 1; i--)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 90),
                      width:
                          size +
                          i * (listening ? 12 + 24 * level : 8) +
                          breathe * 14 * i,
                      height:
                          size +
                          i * (listening ? 12 + 24 * level : 8) +
                          breathe * 14 * i,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.ink.withValues(
                          alpha: listening ? 0.07 + 0.05 * level : 0.05,
                        ),
                      ),
                    ),
                  if (listening)
                    SizedBox(
                      width: size + 14,
                      height: size + 14,
                      child: CustomPaint(
                        painter: _Arc(
                          progress: (c.elapsed / maxSeconds).clamp(0, 1),
                          color: p.reminder,
                        ),
                      ),
                    ),
                  AnimatedScale(
                    scale: _down || listening ? 0.94 : 1,
                    duration: const Duration(milliseconds: 120),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: p.ink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        working
                            ? Icons.auto_awesome_rounded
                            : listening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_none_rounded,
                        color: p.paper,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Arc extends CustomPainter {
  _Arc({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Offset.zero & size,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_Arc old) =>
      old.progress != progress || old.color != color;
}

/// Recent loudness as thin bars: ink for what's been said, faint dots for
/// the time that's left.
class Waveform extends StatelessWidget {
  const Waveform({super.key, required this.levels, required this.progress});

  final List<double> levels;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SizedBox(
      height: 40,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(levels, progress, p.ink, p.rule),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.levels, this.progress, this.ink, this.rule);

  final List<double> levels;
  final double progress;
  final Color ink;
  final Color rule;

  static const _bars = 52;

  @override
  void paint(Canvas canvas, Size size) {
    final step = size.width / _bars;
    final filled = (progress * _bars).round().clamp(0, _bars);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.6;
    final mid = size.height / 2;
    for (var i = 0; i < _bars; i++) {
      final x = step * (i + 0.5);
      double h;
      if (i < filled) {
        // Spread the recent history over the bars said so far.
        final idx = levels.isEmpty
            ? -1
            : (levels.length - filled + i).clamp(0, levels.length - 1);
        final l = idx < 0 ? 0.0 : levels[idx];
        h = 3 + l * (size.height - 4);
        paint.color = ink;
      } else {
        h = 3;
        paint.color = rule;
      }
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}
