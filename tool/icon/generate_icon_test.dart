// Draws the app icon PNGs. Not part of the normal test run; regenerate with:
//
//   flutter test tool/icon --update-goldens && cp tool/icon/icon_*.png assets/icon/
//   dart run flutter_launcher_icons
//
// The icon is the hold button: an ink circle on paper, with three sorted
// lines inside and the reminder-orange dot of something to act on.
import 'package:brain_dump/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum _Layer { full, foreground, background, monochrome }

class _IconPainter extends CustomPainter {
  _IconPainter(this.layer);

  final _Layer layer;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    const p = Paper.light;
    const rect = Rect.fromLTWH(0, 0, 1024, 1024);

    if (layer == _Layer.full || layer == _Layer.background) {
      canvas.drawRect(rect, Paint()..color = p.paper);
    }
    if (layer == _Layer.background) return;

    // Adaptive icons are masked to a circle or squircle; keep the mark in
    // the middle 66%.
    final scale = layer == _Layer.full ? 1.0 : 0.74;
    canvas.translate(512, 512);
    canvas.scale(scale);
    canvas.translate(-512, -512);

    final mono = layer == _Layer.monochrome;
    final ink = mono ? Colors.white : p.ink;

    // Soft rings, like the button while you talk.
    if (!mono) {
      for (final (r, a) in [(430.0, 0.05), (380.0, 0.07)]) {
        canvas.drawCircle(
          const Offset(512, 512),
          r,
          Paint()..color = p.ink.withValues(alpha: a),
        );
      }
    }
    // The monochrome layer cuts the lines and the dot's gap out of the
    // circle, so it's drawn on its own layer.
    if (mono) canvas.saveLayer(rect, Paint());
    canvas.drawCircle(const Offset(512, 512), 320, Paint()..color = ink);

    // Three sorted lines.
    final cut = Paint()
      ..color = mono ? Colors.black : p.paper
      ..blendMode = mono ? BlendMode.clear : BlendMode.srcOver
      ..strokeCap = StrokeCap.round;
    for (final (y, x2) in [(400.0, 680.0), (512.0, 620.0), (624.0, 700.0)]) {
      canvas.drawLine(Offset(372, y), Offset(x2, y), cut..strokeWidth = 56);
    }

    // The dot: something to act on, with a paper gap around it.
    canvas.drawCircle(const Offset(742, 300), 84, cut..strokeWidth = 0);
    canvas.drawCircle(
      const Offset(742, 300),
      62,
      Paint()..color = mono ? Colors.white : p.reminder,
    );
    if (mono) canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter oldDelegate) => false;
}

void main() {
  for (final layer in _Layer.values) {
    testWidgets('icon ${layer.name}', (tester) async {
      tester.view.physicalSize = const Size(1024, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(1024, 1024),
            painter: _IconPainter(layer),
          ),
        ),
      );
      await expectLater(
        find.byType(RepaintBoundary).first,
        matchesGoldenFile('icon_${layer.name}.png'),
      );
    });
  }
}
