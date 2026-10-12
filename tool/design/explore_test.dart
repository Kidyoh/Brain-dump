// Round 1 of the design exploration: four directions, each drawn as the same
// three screens (idle, recording, sorted) with the same sample ramble.
// Not part of the normal test run. Render with:
//
//   tool/design/get_fonts.sh
//   flutter test tool/design/explore_test.dart --update-goldens
//
// The PNGs land in tool/design/out/ and are copied to docs/design/.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sample.dart';

Future<void> loadDesignFonts() async {
  final dir = Directory('tool/design/fonts');
  final families = <String, List<File>>{};
  for (final f in dir.listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (!name.endsWith('.ttf')) continue;
    final family = name.split('-').first;
    families.putIfAbsent(family, () => []).add(f);
  }
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final f in e.value) {
      loader.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
    }
    await loader.load();
  }
  final flutterRoot = File(Platform.resolvedExecutable)
      .parent
      .parent
      .parent
      .parent
      .parent
      .parent
      .path;
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ).readAsBytesSync();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(icons)))).load();
}

Future<void> renderBoard(
  WidgetTester tester,
  String name,
  List<Widget> screens,
) async {
  await tester.runAsync(loadDesignFonts);
  const phone = Size(390, 844);
  const gap = 40.0;
  final width = screens.length * phone.width + (screens.length + 1) * gap;
  final height = phone.height + 2 * gap;
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(width * 2, height * 2);
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: const ValueKey('board'),
        child: Container(
          color: const Color(0xFFD9D9DE),
          padding: const EdgeInsets.all(gap),
          child: Row(
            children: [
              for (var i = 0; i < screens.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: SizedBox.fromSize(
                    size: phone,
                    child: MediaQuery(
                      data: const MediaQueryData(
                        size: phone,
                        padding: EdgeInsets.only(top: 44, bottom: 24),
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: screens[i],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await expectLater(
    find.byKey(const ValueKey('board')),
    matchesGoldenFile('out/$name.png'),
  );
}

// ---------------------------------------------------------------------------
// A. Notebook: warm paper, ink, serif headlines. Calm and personal.

class _Notebook {
  static const paper = Color(0xFFF3EEE3);
  static const ink = Color(0xFF22201B);
  static const faint = Color(0xFF8C8577);
  static const rule = Color(0xFFDCD4C3);
  static const kind = {
    Kind.task: Color(0xFFF2C94C),
    Kind.reminder: Color(0xFFF2994A),
    Kind.note: Color(0xFF9BB7D4),
    Kind.idea: Color(0xFFA8D5A2),
  };
  static const serif = TextStyle(fontFamily: 'InstrumentSerif', color: ink);
  static const sans = TextStyle(fontFamily: 'Inter', color: ink);
}

Widget notebookIdle() {
  const s = _Notebook.sans;
  return ColoredBox(
    color: _Notebook.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monday, 12 October',
            style: s.copyWith(fontSize: 13, color: _Notebook.faint),
          ),
          const SizedBox(height: 6),
          Text(
            "What's on\nyour mind?",
            style: _Notebook.serif.copyWith(fontSize: 46, height: 1.0),
          ),
          const SizedBox(height: 28),
          Text(
            'Earlier today',
            style: s.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: _Notebook.faint,
            ),
          ),
          const SizedBox(height: 8),
          for (final it in sampleItems.take(4))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _Notebook.rule)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _Notebook.kind[it.kind],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.copyWith(fontSize: 15),
                    ),
                  ),
                  Text(
                    it.kind.label.toLowerCase(),
                    style: _Notebook.serif.copyWith(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: _Notebook.faint,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: _Notebook.ink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mic_none_rounded,
                    color: _Notebook.paper,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Hold and ramble',
                  style: _Notebook.serif.copyWith(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget notebookRecording() {
  const s = _Notebook.sans;
  return ColoredBox(
    color: _Notebook.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 64, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Listening…',
            style: s.copyWith(fontSize: 13, color: _Notebook.faint),
          ),
          const SizedBox(height: 18),
          Text(
            sampleTranscript.substring(0, 210),
            style: _Notebook.serif.copyWith(fontSize: 28, height: 1.2),
          ),
          Text(
            '…',
            style: _Notebook.serif.copyWith(
              fontSize: 28,
              color: _Notebook.faint,
            ),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 132,
              height: 132,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: 14 / 30,
                      strokeWidth: 3,
                      color: _Notebook.ink,
                      backgroundColor: _Notebook.rule,
                    ),
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: _Notebook.ink,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '0:14',
                      style: _Notebook.serif.copyWith(
                        fontSize: 34,
                        color: _Notebook.paper,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Let go when you’re done',
              style: _Notebook.serif.copyWith(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: _Notebook.faint,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget notebookResults() {
  const s = _Notebook.sans;
  Widget section(Kind k) {
    final items = sampleItems.where((i) => i.kind == k).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 18,
              height: 8,
              color: _Notebook.kind[k]!.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 8),
            Text(
              k.plural,
              style: _Notebook.serif.copyWith(
                fontSize: 24,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        for (final it in items)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _Notebook.rule)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.text, style: s.copyWith(fontSize: 15, height: 1.3)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (it.when != null)
                      Text(
                        '${it.when}  ·  ',
                        style: s.copyWith(fontSize: 13, color: _Notebook.faint),
                      ),
                    Text(
                      '${it.action} →',
                      style: s.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  return ColoredBox(
    color: _Notebook.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '28 seconds, sorted',
            style: s.copyWith(fontSize: 13, color: _Notebook.faint),
          ),
          Text(
            'Six things.',
            style: _Notebook.serif.copyWith(fontSize: 46, height: 1.05),
          ),
          for (final k in Kind.values) section(k),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// B. Night orb: dark, a glowing orb that is the button, glass cards.

class _Orb {
  static const bg = Color(0xFF0A0A12);
  static const text = Color(0xFFF2F1F7);
  static const dim = Color(0xFF8E8BA3);
  static const kind = {
    Kind.task: Color(0xFF7C9CFF),
    Kind.reminder: Color(0xFFFF8A5C),
    Kind.note: Color(0xFF5CE1C8),
    Kind.idea: Color(0xFFE59CFF),
  };
  static const sans = TextStyle(fontFamily: 'Manrope', color: text);
}

Widget _orb(double size, {double glow = 1}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: [Color(0xFFFFD1A8), Color(0xFFFF6B9A), Color(0xFF7C5CFF)],
        stops: [0, 0.45, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFF6B9A).withValues(alpha: 0.45 * glow),
          blurRadius: 60 * glow,
          spreadRadius: 6 * glow,
        ),
        BoxShadow(
          color: const Color(0xFF7C5CFF).withValues(alpha: 0.5 * glow),
          blurRadius: 120 * glow,
          spreadRadius: 20 * glow,
        ),
      ],
    ),
  );
}

Widget _glass({required Widget child, EdgeInsets? padding}) => Container(
  padding: padding ?? const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
  ),
  child: child,
);

Widget orbIdle() {
  const s = _Orb.sans;
  return ColoredBox(
    color: _Orb.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Brain dump',
                style: s.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              const Icon(Icons.tune_rounded, color: _Orb.dim),
            ],
          ),
          const Spacer(),
          _orb(190),
          const SizedBox(height: 48),
          Text(
            'Hold the orb and say\neverything on your mind.',
            textAlign: TextAlign.center,
            style: s.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Up to 30 seconds',
            style: s.copyWith(fontSize: 14, color: _Orb.dim),
          ),
          const Spacer(),
          _glass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                for (final k in Kind.values)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${sampleItems.where((i) => i.kind == k).length + 2}',
                          style: s.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _Orb.kind[k],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              k.plural.toLowerCase(),
                              style: s.copyWith(fontSize: 12, color: _Orb.dim),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget orbRecording() {
  const s = _Orb.sans;
  return ColoredBox(
    color: _Orb.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        children: [
          Text(
            '0:14',
            style: s.copyWith(
              fontSize: 56,
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text('of 0:30', style: s.copyWith(color: _Orb.dim)),
          const Spacer(),
          _orb(250, glow: 1.6),
          const Spacer(),
          Text(
            sampleTranscript.substring(120, 260),
            textAlign: TextAlign.center,
            style: s.copyWith(fontSize: 17, color: _Orb.dim, height: 1.5),
          ),
          const SizedBox(height: 24),
          Text(
            'Release to sort',
            style: s.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Widget orbResults() {
  const s = _Orb.sans;
  return ColoredBox(
    color: _Orb.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _orb(28, glow: 0.3),
              const SizedBox(width: 12),
              Text(
                '6 things from 28s',
                style: s.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final it in sampleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _glass(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.kind.label.toUpperCase(),
                            style: s.copyWith(
                              fontSize: 10.5,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: _Orb.kind[it.kind],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            it.text,
                            style: s.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (it.when != null)
                            Text(
                              it.when!,
                              style: s.copyWith(
                                fontSize: 12.5,
                                color: _Orb.dim,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _Orb.kind[it.kind]!.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            it.actionIcon,
                            size: 15,
                            color: _Orb.kind[it.kind],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            it.actionShort,
                            style: s.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _Orb.kind[it.kind],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// C. Sticky blocks: neo-brutalist, thick outlines, loud colour per kind.

class _Blocks {
  static const bg = Color(0xFFFFF6E6);
  static const ink = Color(0xFF111111);
  static const hot = Color(0xFFFF5A36);
  static const kind = {
    Kind.task: Color(0xFFFFD84D),
    Kind.reminder: Color(0xFFFF9BC0),
    Kind.note: Color(0xFF8CCBFF),
    Kind.idea: Color(0xFF8EF0B0),
  };
  static const sans = TextStyle(fontFamily: 'Bricolage', color: ink);
}

Widget _block({
  required Widget child,
  Color color = Colors.white,
  double radius = 18,
  double shadow = 4,
  EdgeInsets padding = const EdgeInsets.all(14),
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _Blocks.ink, width: 2.5),
    boxShadow: [BoxShadow(color: _Blocks.ink, offset: Offset(shadow, shadow))],
  ),
  child: child,
);

Widget blocksIdle() {
  const s = _Blocks.sans;
  return ColoredBox(
    color: _Blocks.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BRAIN\nDUMP.',
            style: s.copyWith(
              fontSize: 54,
              fontWeight: FontWeight.w800,
              height: 0.92,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final k in Kind.values)
                _block(
                  color: _Blocks.kind[k]!,
                  radius: 99,
                  shadow: 2.5,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    '${sampleItems.where((i) => i.kind == k).length + 1} ${k.plural}',
                    style: s.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          _block(
            color: _Blocks.kind[Kind.reminder]!,
            child: Row(
              children: [
                const Icon(Icons.alarm_rounded, color: _Blocks.ink),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pick up Liya from practice',
                    style: s.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text('5:30', style: s.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Spacer(),
          _block(
            color: _Blocks.hot,
            radius: 28,
            shadow: 6,
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  const Icon(Icons.mic_rounded, size: 46, color: _Blocks.ink),
                  const SizedBox(height: 6),
                  Text(
                    'HOLD & RAMBLE',
                    style: s.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '30 seconds. Say it all.',
                    style: s.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget blocksRecording() {
  const s = _Blocks.sans;
  final rnd = math.Random(4);
  return ColoredBox(
    color: _Blocks.hot,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0:14',
            style: s.copyWith(
              fontSize: 120,
              fontWeight: FontWeight.w800,
              height: 0.9,
            ),
          ),
          Text(
            '16 seconds left',
            style: s.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < 26; i++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 10 + rnd.nextDouble() * 78,
                      decoration: BoxDecoration(
                        color: _Blocks.ink,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          _block(
            child: Text(
              sampleTranscript.substring(0, 170),
              style: s.copyWith(fontSize: 17, height: 1.35),
            ),
          ),
          const SizedBox(height: 22),
          Center(
            child: Text(
              'LET GO TO SORT IT',
              style: s.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget blocksResults() {
  const s = _Blocks.sans;
  return ColoredBox(
    color: _Blocks.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6 things. Sorted.',
            style: s.copyWith(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final it in sampleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _block(
                color: _Blocks.kind[it.kind]!,
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.kind.label.toUpperCase(),
                            style: s.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            it.text,
                            style: s.copyWith(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _Blocks.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(it.actionIcon, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// D. Signal: minimal monochrome, one red accent while recording.

class _Signal {
  static const bg = Color(0xFFFAFAFA);
  static const ink = Color(0xFF0E0E0E);
  static const dim = Color(0xFF8A8A8A);
  static const line = Color(0xFFE8E8E8);
  static const red = Color(0xFFFF3B30);
  static const sans = TextStyle(fontFamily: 'Inter', color: ink);
}

Widget signalIdle() {
  const s = _Signal.sans;
  return ColoredBox(
    color: _Signal.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inbox',
            style: s.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '3 tasks · 1 reminder · 1 note · 1 idea',
            style: s.copyWith(fontSize: 14, color: _Signal.dim),
          ),
          const SizedBox(height: 20),
          for (final it in sampleItems.take(5))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _Signal.line)),
              ),
              child: Row(
                children: [
                  Icon(it.kind.icon, size: 18, color: _Signal.dim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      it.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: s.copyWith(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: _Signal.ink,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: _Signal.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Hold to talk',
                  style: s.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget signalRecording() {
  const s = _Signal.sans;
  final rnd = math.Random(9);
  return ColoredBox(
    color: _Signal.red,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
      child: Column(
        children: [
          const Spacer(),
          Text(
            '0:14',
            style: s.copyWith(
              fontSize: 96,
              color: Colors.white,
              fontWeight: FontWeight.w300,
              letterSpacing: -4,
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < 40; i++)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 3,
                        height: 4 + rnd.nextDouble() * 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: i < 19 ? 1 : 0.35,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            'Release to sort',
            style: s.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget signalResults() {
  const s = _Signal.sans;
  return ColoredBox(
    color: _Signal.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sorted',
            style: s.copyWith(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          for (final k in Kind.values) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Text(
                k.plural.toUpperCase(),
                style: s.copyWith(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: _Signal.dim,
                ),
              ),
            ),
            for (final it in sampleItems.where((i) => i.kind == k))
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _Signal.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.text, style: s.copyWith(fontSize: 15)),
                          if (it.when != null)
                            Text(
                              it.when!,
                              style: s.copyWith(
                                fontSize: 12.5,
                                color: _Signal.dim,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: _Signal.ink),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        it.actionShort,
                        style: s.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    ),
  );
}

void main() {
  testWidgets('A notebook', (t) async {
    await renderBoard(t, 'A_notebook', [
      notebookIdle(),
      notebookRecording(),
      notebookResults(),
    ]);
  });
  testWidgets('B orb', (t) async {
    await renderBoard(t, 'B_orb', [orbIdle(), orbRecording(), orbResults()]);
  });
  testWidgets('C blocks', (t) async {
    await renderBoard(t, 'C_blocks', [
      blocksIdle(),
      blocksRecording(),
      blocksResults(),
    ]);
  });
  testWidgets('D signal', (t) async {
    await renderBoard(t, 'D_signal', [
      signalIdle(),
      signalRecording(),
      signalResults(),
    ]);
  });
}
