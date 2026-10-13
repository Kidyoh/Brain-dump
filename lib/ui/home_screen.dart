import 'package:flutter/material.dart';

import '../capture/capture.dart';
import '../data/models.dart';
import '../data/settings.dart';
import '../data/when.dart';
import '../theme.dart';
import 'history_screen.dart';
import 'hold_button.dart';
import 'item_card.dart';
import 'results_screen.dart';
import 'scope.dart';
import 'settings_screen.dart';
import 'type_sheet.dart';

/// The one main screen: your open items, and the hold button. While you
/// hold it, the list gives way to your words as you say them.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CaptureController? _capture;
  bool _showingResult = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final c = Scope.of(context).capture;
    if (c != _capture) {
      _capture?.removeListener(_changed);
      _capture = c..addListener(_changed);
    }
  }

  @override
  void dispose() {
    _capture?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    final c = _capture!;
    if (c.result != null && !_showingResult) {
      _showingResult = true;
      final dump = c.result!;
      Navigator.of(context)
          .push(
            PageRouteBuilder<void>(
              transitionDuration: const Duration(milliseconds: 420),
              reverseTransitionDuration: const Duration(milliseconds: 260),
              pageBuilder: (_, _, _) => ResultsScreen(dump: dump),
              transitionsBuilder: (_, anim, _, child) {
                final curved = CurvedAnimation(
                  parent: anim,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
            ),
          )
          .then((_) {
            _showingResult = false;
            c.dismiss();
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final capture = Scope.of(context).capture;
    return Scaffold(
      body: ListenableBuilder(
        listenable: capture,
        builder: (context, _) {
          final capturing = capture.phase != Phase.idle;
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: capturing
                      ? _CaptureView(
                          key: const ValueKey('capture'),
                          capture: capture,
                        )
                      : const _Inbox(key: ValueKey('inbox')),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [p.paper.withValues(alpha: 0), p.paper],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _BottomControls(capture: capture),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({required this.capture});

  final CaptureController capture;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final label = switch (capture.phase) {
      Phase.listening => 'Let go when you’re done',
      Phase.working => capture.stage,
      Phase.failed => '',
      Phase.idle =>
        capture.tooShort ? 'Keep holding while you talk' : 'Hold and ramble',
    };
    return Container(
      color: p.paper,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (capture.phase == Phase.listening)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Waveform(
                levels: capture.levels,
                progress: capture.elapsed / maxSeconds,
              ),
            ),
          if (capture.phase != Phase.failed) HoldButton(capture: capture),
          SizedBox(
            height: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                label,
                key: ValueKey(label),
                style: p.serif(
                  23,
                  italic: true,
                  color: capture.phase == Phase.idle && !capture.tooShort
                      ? p.ink
                      : p.faint,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: capture.phase == Phase.idle
                ? TextButton(
                    onPressed: () => showTypeSheet(context),
                    style: TextButton.styleFrom(foregroundColor: p.faint),
                    child: Text(
                      'or type it',
                      style: p.sans(
                        13.5,
                        weight: FontWeight.w500,
                        color: p.faint,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// While holding: your words, big. While sorting: the same words, fading.
class _CaptureView extends StatelessWidget {
  const _CaptureView({super.key, required this.capture});

  final CaptureController capture;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final top = MediaQuery.paddingOf(context).top;
    if (capture.phase == Phase.failed) {
      return Padding(
        padding: EdgeInsets.fromLTRB(28, top + 64, 28, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hmm.', style: p.serif(52)),
            const SizedBox(height: 12),
            Text(
              capture.error ?? 'Something went wrong.',
              style: p.sans(17, height: 1.45),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                if (capture.canRetry) ...[
                  FilledButton(
                    onPressed: capture.retry,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                    ),
                    child: const Text('Try again'),
                  ),
                  const SizedBox(width: 10),
                ],
                TextButton(
                  onPressed: capture.dismiss,
                  child: Text(capture.canRetry ? 'Discard' : 'OK'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final listening = capture.phase == Phase.listening;
    final words = capture.words.trim();
    final whisper =
        Scope.of(context).settings.effectiveHearing == Hearing.whisper;
    final secs = capture.elapsed.floor();

    Widget body;
    if (words.isEmpty) {
      body = Text(
        listening
            ? whisper
                  ? 'Recording. Say everything that’s on your mind: errands, '
                        'plans, that thing you keep forgetting…'
                  : 'Go ahead, I’m listening…'
            : '…',
        style: p.serif(31, color: p.faint).copyWith(height: 1.18),
      );
    } else {
      // The last few words are still settling, so they stay faint.
      final cut = listening && words.length > 30
          ? words.lastIndexOf(' ', words.length - 18).clamp(0, words.length)
          : words.length;
      body = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: words.substring(0, cut)),
            TextSpan(
              text: words.substring(cut),
              style: TextStyle(color: p.faint),
            ),
          ],
        ),
        style: p
            .serif(31, color: listening ? p.ink : p.faint)
            .copyWith(height: 1.18),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(28, top + 24, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (listening)
                _BlinkDot(color: p.reminder)
              else
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    color: p.faint,
                  ),
                ),
              const SizedBox(width: 9),
              Text(
                listening ? 'Listening' : capture.stage,
                style: p.sans(13.5, color: p.faint),
              ),
              const Spacer(),
              if (listening)
                Text(
                  '0:${secs.toString().padLeft(2, '0')} / 0:$maxSeconds',
                  style: p
                      .sans(13.5, color: p.faint)
                      .copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
                stops: [0, 0.12],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                reverse: true,
                padding: const EdgeInsets.only(top: 24, bottom: 340),
                child: SizedBox(width: double.infinity, child: body),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  const _BlinkDot({required this.color});

  final Color color;

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
    child: Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}

/// Your open items: counts per kind, what's coming up, then everything else.
class _Inbox extends StatefulWidget {
  const _Inbox({super.key});

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  Kind? _filter;
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final store = Scope.of(context).store;
    final top = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = appClock();
        final open = store.openItems.toList();
        final done = store.items.where((i) => i.done).toList();
        final upNext = _filter == null
            ? store.upNext(now).take(4).toList()
            : <Item>[];
        final rest = open.where((i) => !upNext.contains(i)).toList();

        final children = <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(26, top + 14, 12, 0),
            child: Row(
              children: [
                Text(longDate(now), style: p.sans(13.5, color: p.faint)),
                const Spacer(),
                IconButton(
                  tooltip: 'Past dumps',
                  icon: Icon(Icons.history_rounded, color: p.faint),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const HistoryScreen(),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Settings',
                  icon: Icon(Icons.tune_rounded, color: p.faint),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(26, 0, 26, 0),
            child: Text(
              "What's on\nyour mind?",
              style: p.serif(50).copyWith(height: 1.0),
            ),
          ),
          if (store.dumps.isNotEmpty) ...[
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  for (final k in Kind.values) ...[
                    Expanded(
                      child: _CountTile(
                        kind: k,
                        count: store.openCount(k),
                        selected: _filter == k,
                        onTap: () =>
                            setState(() => _filter = _filter == k ? null : k),
                      ),
                    ),
                    if (k != Kind.idea) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ],
        ];

        if (store.dumps.isEmpty) {
          children.add(const _EmptyHints());
        } else if (_filter != null) {
          final list = open.where((i) => i.kind == _filter).toList();
          children.add(_section(context, _filter!.plural, list));
          if (list.isEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 4, 26, 0),
                child: Text(
                  'No open ${_filter!.plural.toLowerCase()}.',
                  style: p.sans(15, color: p.faint),
                ),
              ),
            );
          }
        } else {
          if (upNext.isNotEmpty) {
            children.add(_section(context, 'Up next', upNext));
          }
          for (final k in Kind.values) {
            final list = rest.where((i) => i.kind == k).toList();
            if (list.isNotEmpty) {
              children.add(_section(context, k.plural, list));
            }
          }
          if (open.isEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 0),
                child: Text(
                  'All clear. Hold the button when your head fills up again.',
                  style: p.serif(24, italic: true, color: p.faint),
                ),
              ),
            );
          }
        }

        if (done.isNotEmpty && _filter == null) {
          children.add(
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showDone = !_showDone),
                  icon: Icon(
                    _showDone
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: p.faint,
                  ),
                  label: Text(
                    _showDone ? 'Hide done' : '${done.length} done',
                    style: p.sans(14, weight: FontWeight.w500, color: p.faint),
                  ),
                ),
              ),
            ),
          );
          if (_showDone) {
            for (final i in done) {
              children.add(ItemRow(key: ValueKey('done-${i.id}'), item: i));
            }
          }
        }

        return ListView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + 230,
          ),
          children: children,
        );
      },
    );
  }

  Widget _section(BuildContext context, String title, List<Item> items) {
    final p = Paper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 4),
          child: Text(title, style: p.serif(24, italic: true)),
        ),
        for (final i in items)
          ItemRow(key: ValueKey('${title}_${i.id}'), item: i),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.kind,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final Kind kind;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '$count open ${kind.plural.toLowerCase()}',
      excludeSemantics: true,
      child: Material(
        color: selected ? p.kind(kind).withValues(alpha: 0.2) : p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? p.kind(kind) : p.rule,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                Text('$count', style: p.serif(28).copyWith(height: 1)),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: p.kind(kind),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        kind.plural.toLowerCase(),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: p.sans(11.5, color: p.faint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyHints extends StatelessWidget {
  const _EmptyHints();

  static const _examples = [
    '“I need to call the dentist and book the car in for a service…”',
    '“Remind me to pick up Liya at five thirty tomorrow.”',
    '“Idea: a podcast where two people swap phones for a day.”',
    '“The studio wifi password is sunflower22.”',
  ];

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 28, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hold the button and say everything at once. Try something like:',
            style: p.sans(15, color: p.faint, height: 1.45),
          ),
          const SizedBox(height: 14),
          for (final e in _examples)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(e, style: p.serif(22, italic: true)),
            ),
        ],
      ),
    );
  }
}
