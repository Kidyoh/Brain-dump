import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/when.dart';
import '../theme.dart';
import 'item_card.dart';
import 'scope.dart';
import 'widgets.dart';

/// What a dump was sorted into: "28 seconds, sorted. Six things." and a card
/// with one-tap actions for each.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.dump, this.fresh = true});

  final Dump dump;

  /// Just recorded (vs. opened from history).
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final store = Scope.of(context).store;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(fresh ? Icons.close_rounded : Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          // Sorted by kind so all tasks sit together, then in spoken order.
          final items = [...dump.items]
            ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
          return ListView(
            padding: EdgeInsets.fromLTRB(
              18,
              0,
              18,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fresh
                          ? dump.seconds > 0
                                ? '${dump.seconds} seconds, sorted'
                                : 'Sorted'
                          : '${dayLabel(dump.createdAt, appClock())}, ${clock(dump.createdAt)}',
                      style: p.sans(13.5, color: p.faint),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thingsHeadline(items.length),
                      style: p.serif(46, color: p.ink).copyWith(height: 1.05),
                    ),
                  ],
                ),
              ),
              if (dump.note != null) _Notice(dump.note!),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 20),
                  child: Text(
                    'Nothing to sort in that one. Try saying what you need to do, '
                    'when, and anything you want to remember.',
                    style: p.sans(15, color: p.faint, height: 1.45),
                  ),
                ),
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ItemCard(key: ValueKey(item.id), item: item),
                ),
              const SizedBox(height: 10),
              _Transcript(dump: dump),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: fresh
          ? SizedBox(
              width: MediaQuery.sizeOf(context).width - 36,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            )
          : null,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.reminder.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: p.ink),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: p.sans(13.5, height: 1.4))),
        ],
      ),
    );
  }
}

/// "What you said", folded away under the cards.
class _Transcript extends StatelessWidget {
  const _Transcript({required this.dump});

  final Dump dump;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 6),
        childrenPadding: const EdgeInsets.fromLTRB(6, 0, 6, 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: p.faint,
        collapsedIconColor: p.faint,
        title: Text('What you said', style: p.serif(22, italic: true)),
        subtitle: Text(
          'Heard by ${dump.heardBy.label}, sorted by ${dump.sortedBy.label}',
          style: p.sans(12.5, color: p.faint),
        ),
        children: [
          SelectableText(
            dump.transcript,
            style: p.serif(22, color: p.ink).copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }
}
