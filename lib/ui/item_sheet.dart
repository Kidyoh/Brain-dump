import 'package:flutter/material.dart';

import '../actions/reminders.dart';
import '../data/models.dart';
import '../data/when.dart';
import '../theme.dart';
import 'item_actions.dart';
import 'item_card.dart';
import 'scope.dart';

/// Opens an item to fix the wording, change what kind it is, set a time,
/// or delete it. Changes save as you go.
Future<void> showItemSheet(BuildContext context, Item item) =>
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ItemSheet(item: item),
    );

class _ItemSheet extends StatefulWidget {
  const _ItemSheet({required this.item});

  final Item item;

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final _text = TextEditingController(text: widget.item.text);
  late final _details = TextEditingController(text: widget.item.details ?? '');

  Item get item => widget.item;

  @override
  void dispose() {
    _text.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _text.text.trim();
    if (text.isNotEmpty) item.text = text;
    final details = _details.text.trim();
    item.details = details.isEmpty ? null : details;
    await Scope.of(context).store.changed();
  }

  Future<void> _setKind(Kind k) async {
    setState(() => item.kind = k);
    await Scope.of(context).store.changed();
  }

  Future<void> _pickWhen() async {
    final picked = await ItemActions(context)
        .pickDateTime(ItemActions.suggestedTime(item, appClock()));
    if (picked == null || !mounted) return;
    setState(() {
      item.due = picked;
      item.allDay = false;
    });
    await Scope.of(context).store.changed();
  }

  Future<void> _clearWhen() async {
    if (item.hasReminder && item.notificationId != null) {
      await Reminders.instance.cancel(item.notificationId!);
    }
    setState(() {
      item.due = null;
      item.allDay = false;
      item.reminderAt = null;
    });
    if (mounted) await Scope.of(context).store.changed();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final store = Scope.of(context).store;
    final dump = store.dumpOf(item);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(
          left: 22,
          right: 22,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final k in Kind.values) ...[
                    Expanded(
                      child: _KindChoice(
                        kind: k,
                        selected: item.kind == k,
                        onTap: () => _setKind(k),
                      ),
                    ),
                    if (k != Kind.idea) const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _text,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: p.sans(17, weight: FontWeight.w500),
                decoration: const InputDecoration(hintText: 'What is it?'),
                onChanged: (_) => _save(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _details,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: p.sans(15),
                decoration: const InputDecoration(hintText: 'Details'),
                onChanged: (_) => _save(),
              ),
              const SizedBox(height: 10),
              Material(
                color: p.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: p.rule),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(Icons.schedule_rounded, color: p.faint),
                  title: Text(
                    item.due == null
                        ? 'Add a time'
                        : whenLabel(item.due!, allDay: item.allDay),
                    style: p.sans(
                      15,
                      color: item.due == null ? p.faint : p.ink,
                    ),
                  ),
                  trailing: item.due == null
                      ? null
                      : IconButton(
                          tooltip: 'Remove time',
                          onPressed: _clearWhen,
                          icon: Icon(Icons.close_rounded, color: p.faint),
                        ),
                  onTap: _pickWhen,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: itemPills(context, item),
              ),
              const SizedBox(height: 18),
              Divider(color: p.rule),
              Row(
                children: [
                  if (dump != null)
                    Expanded(
                      child: Text(
                        'From your ${dump.seconds > 0 ? '${dump.seconds}-second dump' : 'typed dump'}, '
                        '${dayLabel(dump.createdAt, appClock()).toLowerCase()} at ${clock(dump.createdAt)}',
                        style: p.sans(12.5, color: p.faint),
                      ),
                    )
                  else
                    const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      final actions = ItemActions(context);
                      Navigator.pop(context);
                      actions.delete(item);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindChoice extends StatelessWidget {
  const _KindChoice({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final Kind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Material(
      color: selected ? p.kind(kind).withValues(alpha: 0.22) : p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? p.kind(kind) : p.rule,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(kind.icon, size: 20, color: p.ink),
              const SizedBox(height: 3),
              Text(kind.label, style: p.sans(12, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
