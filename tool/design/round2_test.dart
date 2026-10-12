// Round 2 of the design exploration: the two strongest round 1 directions,
// refined. E takes A (Notebook) and gives it B's tappable action pills, a
// bigger voice-reactive button and a dark mode. F tones C (Blocks) down.
//
//   flutter test tool/design/round2_test.dart --update-goldens
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'explore_test.dart' show renderBoard;
import 'sample.dart';

// ---------------------------------------------------------------------------
// E. Paper

class PaperLook {
  const PaperLook({
    required this.paper,
    required this.card,
    required this.ink,
    required this.faint,
    required this.rule,
    required this.kind,
  });

  final Color paper;
  final Color card;
  final Color ink;
  final Color faint;
  final Color rule;
  final Map<Kind, Color> kind;

  static const light = PaperLook(
    paper: Color(0xFFF4EFE6),
    card: Color(0xFFFBF8F2),
    ink: Color(0xFF221F1A),
    faint: Color(0xFF8C8577),
    rule: Color(0xFFE2DACB),
    kind: {
      Kind.task: Color(0xFFE9B949),
      Kind.reminder: Color(0xFFE5793F),
      Kind.note: Color(0xFF6E97C4),
      Kind.idea: Color(0xFF6FB07A),
    },
  );

  static const dark = PaperLook(
    paper: Color(0xFF191714),
    card: Color(0xFF231F1B),
    ink: Color(0xFFF1EBDF),
    faint: Color(0xFF8F877A),
    rule: Color(0xFF332E28),
    kind: {
      Kind.task: Color(0xFFF0C55A),
      Kind.reminder: Color(0xFFF08A52),
      Kind.note: Color(0xFF8DB2DB),
      Kind.idea: Color(0xFF8CCB95),
    },
  );

  TextStyle get serif => TextStyle(fontFamily: 'InstrumentSerif', color: ink);
  TextStyle get sans => TextStyle(fontFamily: 'Inter', color: ink);
}

Widget _paperButton(PaperLook p, {double level = 0, double size = 112}) {
  return SizedBox(
    width: size + 70,
    height: size + 70,
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 2; i >= 1; i--)
          Container(
            width: size + i * (10 + 22 * level),
            height: size + i * (10 + 22 * level),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.ink.withValues(alpha: 0.06 + 0.04 * level),
            ),
          ),
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
          child: Icon(Icons.mic_none_rounded, color: p.paper, size: 42),
        ),
      ],
    ),
  );
}

Widget _pill(PaperLook p, SampleItem it, {bool filled = false}) {
  final c = p.kind[it.kind]!;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: filled ? p.ink : c.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(it.actionIcon, size: 15, color: filled ? p.paper : p.ink),
        const SizedBox(width: 6),
        Text(
          it.action,
          style: p.sans.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: filled ? p.paper : p.ink,
          ),
        ),
      ],
    ),
  );
}

Widget paperIdle(PaperLook p) {
  return ColoredBox(
    color: p.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(26, 60, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Monday, 12 October',
                style: p.sans.copyWith(fontSize: 13, color: p.faint),
              ),
              const Spacer(),
              Icon(Icons.tune_rounded, size: 20, color: p.faint),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "What's on\nyour mind?",
            style: p.serif.copyWith(fontSize: 48, height: 1.0),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              for (final k in Kind.values) ...[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.rule),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${sampleItems.where((i) => i.kind == k).length + 1}',
                          style: p.serif.copyWith(fontSize: 26, height: 1),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: p.kind[k],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              k.plural.toLowerCase(),
                              style: p.sans.copyWith(
                                fontSize: 11,
                                color: p.faint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (k != Kind.idea) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'Up next',
            style: p.serif.copyWith(fontSize: 22, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          for (final it in [sampleItems[1], sampleItems[3], sampleItems[0]])
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.rule)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      color: p.kind[it.kind],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          it.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: p.sans.copyWith(fontSize: 15),
                        ),
                        Text(
                          it.when ?? it.kind.label,
                          style: p.sans.copyWith(fontSize: 12, color: p.faint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Center(child: _paperButton(p)),
          Center(
            child: Text(
              'Hold and ramble',
              style: p.serif.copyWith(
                fontSize: 22,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget paperRecording(PaperLook p) {
  final rnd = math.Random(3);
  return ColoredBox(
    color: p.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(26, 60, 26, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.kind[Kind.reminder],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Listening',
                style: p.sans.copyWith(fontSize: 13, color: p.faint),
              ),
              const Spacer(),
              Text(
                '0:14 / 0:30',
                style: p.sans.copyWith(
                  fontSize: 13,
                  color: p.faint,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: sampleTranscript.substring(0, 168)),
                TextSpan(
                  text: sampleTranscript.substring(168, 210),
                  style: TextStyle(color: p.faint),
                ),
              ],
            ),
            style: p.serif.copyWith(fontSize: 29, height: 1.18),
          ),
          const Spacer(),
          SizedBox(
            height: 36,
            child: Row(
              children: [
                for (var i = 0; i < 48; i++)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2.5,
                        height: 3 + rnd.nextDouble() * (i < 30 ? 32 : 6),
                        decoration: BoxDecoration(
                          color: i < 30 ? p.ink : p.rule,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(child: _paperButton(p, level: 0.8)),
          Center(
            child: Text(
              'Let go when you’re done',
              style: p.serif.copyWith(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: p.faint,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget paperResults(PaperLook p) {
  Widget card(SampleItem it) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.kind[it.kind],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                it.kind.label,
                style: p.serif.copyWith(
                  fontSize: 17,
                  fontStyle: FontStyle.italic,
                  color: p.faint,
                ),
              ),
              const Spacer(),
              if (it.when != null)
                Text(
                  it.when!,
                  style: p.sans.copyWith(fontSize: 12, color: p.faint),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            it.text,
            style: p.sans.copyWith(
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          _pill(p, it, filled: it.kind == Kind.reminder),
        ],
      ),
    );
  }

  return ColoredBox(
    color: p.paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 56, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '28 seconds, sorted',
                  style: p.sans.copyWith(fontSize: 13, color: p.faint),
                ),
                Text(
                  'Six things.',
                  style: p.serif.copyWith(fontSize: 44, height: 1.05),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final it in sampleItems.take(5)) card(it),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// F. Soft blocks

class _F {
  static const bg = Color(0xFFFBF5EC);
  static const ink = Color(0xFF1B1A1F);
  static const hot = Color(0xFFFF6B4A);
  static const kind = {
    Kind.task: Color(0xFFFFE08A),
    Kind.reminder: Color(0xFFFFB8C9),
    Kind.note: Color(0xFFB9DCFF),
    Kind.idea: Color(0xFFBDF0CB),
  };
  static const sans = TextStyle(fontFamily: 'Bricolage', color: ink);
}

Widget _fBlock({
  required Widget child,
  Color color = Colors.white,
  double radius = 20,
  EdgeInsets padding = const EdgeInsets.all(14),
}) => Container(
  padding: padding,
  decoration: BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _F.ink, width: 1.6),
    boxShadow: const [BoxShadow(color: _F.ink, offset: Offset(0, 3))],
  ),
  child: child,
);

Widget softIdle() {
  const s = _F.sans;
  return ColoredBox(
    color: _F.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Brain dump',
            style: s.copyWith(fontSize: 36, fontWeight: FontWeight.w800),
          ),
          Text(
            'Empty your head. We’ll sort it.',
            style: s.copyWith(
              fontSize: 15,
              color: _F.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.7,
            children: [
              for (final k in Kind.values)
                _fBlock(
                  color: _F.kind[k]!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(k.icon, size: 22),
                      const Spacer(),
                      Text(
                        '${sampleItems.where((i) => i.kind == k).length + 1} ${k.plural.toLowerCase()}',
                        style: s.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: _F.hot,
                shape: BoxShape.circle,
                border: Border.all(color: _F.ink, width: 2),
                boxShadow: const [
                  BoxShadow(color: _F.ink, offset: Offset(0, 5)),
                ],
              ),
              child: const Icon(Icons.mic_rounded, size: 56, color: _F.ink),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Hold & ramble',
              style: s.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget softRecording() {
  const s = _F.sans;
  return ColoredBox(
    color: _F.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 60, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0:14',
            style: s.copyWith(fontSize: 64, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _fBlock(
            child: Text(
              sampleTranscript.substring(0, 210),
              style: s.copyWith(fontSize: 18, height: 1.35),
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                color: _F.hot.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  color: _F.hot,
                  shape: BoxShape.circle,
                  border: Border.all(color: _F.ink, width: 2),
                ),
                child: const Icon(Icons.graphic_eq_rounded, size: 60),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Let go to sort',
              style: s.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget softResults() {
  const s = _F.sans;
  return ColoredBox(
    color: _F.bg,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 56, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '6 things, sorted',
            style: s.copyWith(fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          for (final it in sampleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 11),
              child: _fBlock(
                color: _F.kind[it.kind]!,
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Icon(it.kind.icon, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it.text,
                        style: s.copyWith(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: _F.ink, width: 1.4),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        it.actionShort,
                        style: s.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
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

void main() {
  testWidgets('E paper', (t) async {
    await renderBoard(t, 'E_paper', [
      paperIdle(PaperLook.light),
      paperRecording(PaperLook.light),
      paperResults(PaperLook.light),
    ]);
  });
  testWidgets('E paper dark', (t) async {
    await renderBoard(t, 'E_paper_dark', [
      paperIdle(PaperLook.dark),
      paperRecording(PaperLook.dark),
      paperResults(PaperLook.dark),
    ]);
  });
  testWidgets('F soft blocks', (t) async {
    await renderBoard(t, 'F_soft_blocks', [
      softIdle(),
      softRecording(),
      softResults(),
    ]);
  });
}
