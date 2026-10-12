import 'package:flutter/material.dart';

import '../actions/reminders.dart';
import '../data/models.dart';
import '../data/when.dart';
import '../theme.dart';
import 'results_screen.dart';
import 'scope.dart';
import 'widgets.dart';

/// Every dump, newest first, with what you said and what it became.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final store = Scope.of(context).store;
    return Scaffold(
      appBar: AppBar(title: const Text('Past dumps')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final dumps = store.dumps;
          if (dumps.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'Your dumps will show up here.',
                  textAlign: TextAlign.center,
                  style: p.serif(24, italic: true, color: p.faint),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
            itemCount: dumps.length,
            separatorBuilder: (_, _) =>
                Divider(indent: 24, endIndent: 24, color: p.rule),
            itemBuilder: (context, i) => _DumpTile(dump: dumps[i]),
          );
        },
      ),
    );
  }
}

class _DumpTile extends StatelessWidget {
  const _DumpTile({required this.dump});

  final Dump dump;

  Future<void> _delete(BuildContext context) async {
    final store = Scope.of(context).store;
    final messenger = ScaffoldMessenger.of(context);
    for (final i in dump.items) {
      if (i.hasReminder && i.notificationId != null) {
        await Reminders.instance.cancel(i.notificationId!);
        i.reminderAt = null;
      }
    }
    final undo = await store.removeDump(dump);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Dump deleted.'),
          action: SnackBarAction(label: 'Undo', onPressed: undo),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final counts = {
      for (final k in Kind.values)
        k: dump.items.where((i) => i.kind == k).length,
    }..removeWhere((_, n) => n == 0);
    return Dismissible(
      key: ValueKey(dump.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: p.reminder.withValues(alpha: 0.18),
        child: Icon(Icons.delete_outline_rounded, color: p.ink),
      ),
      onDismissed: (_) => _delete(context),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ResultsScreen(dump: dump, fresh: false),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dayLabel(dump.createdAt, DateTime.now())}, ${clock(dump.createdAt)}',
                      style: p.sans(12.5, color: p.faint),
                    ),
                  ),
                  if (dump.seconds > 0)
                    Text(
                      '${dump.seconds}s',
                      style: p.sans(12.5, color: p.faint),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                dump.title ?? thingsHeadline(dump.items.length),
                style: p.serif(25),
              ),
              const SizedBox(height: 4),
              Text(
                dump.transcript,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: p.sans(14, color: p.faint, height: 1.4),
              ),
              if (counts.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  children: [
                    for (final e in counts.entries)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          KindDot(e.key, size: 7),
                          const SizedBox(width: 5),
                          Text(
                            '${e.value} ${(e.value == 1 ? e.key.label : e.key.plural).toLowerCase()}',
                            style: p.sans(12.5),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
