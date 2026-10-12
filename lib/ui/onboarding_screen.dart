import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';
import 'scope.dart';
import 'widgets.dart';

/// Three pages on first launch: say it, it gets sorted, act in one tap.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pages.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    } else {
      Scope.of(context).settings.setOnboarded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 10, 0),
                child: AnimatedOpacity(
                  opacity: _page < 2 ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: _page < 2
                        ? () => Scope.of(context).settings.setOnboarded()
                        : null,
                    child: Text('Skip', style: p.sans(14, color: p.faint)),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: const [
                  _Page(
                    title: 'Say it all.',
                    body:
                        'Hold the button and ramble for up to 30 seconds. '
                        'Errands, plans, that thing you keep forgetting. '
                        'No need to be tidy.',
                    art: _SayArt(),
                  ),
                  _Page(
                    title: 'It gets sorted.',
                    body:
                        'Let go, and your ramble comes back as tasks, '
                        'reminders, notes and ideas.',
                    art: _SortArt(),
                  ),
                  _Page(
                    title: 'One tap to act.',
                    body:
                        'Add a task to your calendar, set a reminder, copy '
                        'a note or share an idea. Done before you forget.',
                    art: _ActArt(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 18),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _page ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _page ? p.ink : p.rule,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                    ),
                    child: Text(_page < 2 ? 'Next' : 'Start'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.body, required this.art});

  final String title;
  final String body;
  final Widget art;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Center(child: art)),
          Text(title, style: p.serif(52).copyWith(height: 1.0)),
          const SizedBox(height: 12),
          Text(body, style: p.sans(16.5, color: p.faint, height: 1.45)),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _SayArt extends StatelessWidget {
  const _SayArt();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text:
                    'Okay so, I need to call the dentist, and remind me to '
                    'pick up Liya at five thirty, oh and ',
              ),
              TextSpan(
                text: 'buy oat milk…',
                style: TextStyle(color: p.faint),
              ),
            ],
          ),
          style: p.serif(30).copyWith(height: 1.18),
        ),
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: p.ink,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.ink.withValues(alpha: 0.08),
                  spreadRadius: 14,
                ),
                BoxShadow(
                  color: p.ink.withValues(alpha: 0.05),
                  spreadRadius: 30,
                ),
              ],
            ),
            child: Icon(Icons.graphic_eq_rounded, color: p.paper, size: 36),
          ),
        ),
      ],
    );
  }
}

class _SortArt extends StatelessWidget {
  const _SortArt();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    const rows = [
      (Kind.task, 'Call the dentist'),
      (Kind.reminder, 'Pick up Liya, 5:30 PM'),
      (Kind.task, 'Buy oat milk'),
      (Kind.idea, 'Podcast: swap phones for a day'),
      (Kind.note, 'Wifi password: sunflower22'),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, (k, t)) in rows.indexed)
          Transform.translate(
            offset: Offset(i.isEven ? -8 : 8, 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.rule),
              ),
              child: Row(
                children: [
                  KindDot(k, size: 9),
                  const SizedBox(width: 10),
                  Text(
                    k.label,
                    style: p.serif(18, italic: true, color: p.faint),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: p.sans(15, weight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActArt extends StatelessWidget {
  const _ActArt();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.rule),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const KindDot(Kind.reminder),
              const SizedBox(width: 7),
              Text(
                'Reminder',
                style: p.serif(18, italic: true, color: p.faint),
              ),
              const Spacer(),
              Text('Tomorrow, 5:30 PM', style: p.sans(12.5, color: p.faint)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pick up Liya from practice',
            style: p.sans(17, weight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionPill(
                icon: Icons.alarm_add_rounded,
                label: 'Set reminder',
                style: PillStyle.filled,
                onTap: () {},
              ),
              ActionPill(
                icon: Icons.event_rounded,
                label: 'Add to calendar',
                style: PillStyle.outline,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
