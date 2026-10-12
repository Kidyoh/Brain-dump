import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/when.dart';
import '../theme.dart';
import 'item_actions.dart';
import 'item_sheet.dart';
import 'widgets.dart';

/// The actions an item offers, main one first.
List<Widget> itemPills(BuildContext context, Item item) {
  final p = Paper.of(context);
  final a = ItemActions(context);
  final tint = p.kind(item.kind);

  Widget calendar(PillStyle style) => ActionPill(
    icon: item.inCalendar ? Icons.event_available_rounded : Icons.event_rounded,
    label: item.inCalendar ? 'In calendar' : 'Add to calendar',
    style: style,
    tint: tint,
    onTap: () => a.addToCalendar(item),
  );

  Widget reminder(PillStyle style, {String label = 'Set reminder'}) =>
      item.hasReminder
      ? ActionPill(
          icon: Icons.alarm_on_rounded,
          label: whenLabel(item.reminderAt!),
          style: PillStyle.filled,
          onTap: () => a.setReminder(item, pick: true),
          trailing: GestureDetector(
            onTap: () => a.cancelReminder(item),
            child: Icon(Icons.close_rounded, size: 16, color: p.paper),
          ),
        )
      : ActionPill(
          icon: Icons.alarm_add_rounded,
          label: label,
          style: style,
          tint: tint,
          onTap: () => a.setReminder(item),
        );

  Widget copy(PillStyle style) => ActionPill(
    icon: Icons.content_copy_rounded,
    label: 'Copy',
    style: style,
    tint: tint,
    onTap: () => a.copy(item),
  );

  Widget share(PillStyle style) => ActionPill(
    icon: Icons.ios_share_rounded,
    label: 'Share',
    style: style,
    tint: tint,
    onTap: () => a.share(item),
  );

  return switch (item.kind) {
    Kind.task => [
      calendar(PillStyle.tinted),
      reminder(PillStyle.outline, label: 'Remind me'),
    ],
    Kind.reminder => [reminder(PillStyle.filled), calendar(PillStyle.outline)],
    Kind.note => [copy(PillStyle.tinted), share(PillStyle.outline)],
    Kind.idea => [share(PillStyle.tinted), copy(PillStyle.outline)],
  };
}

/// An item on the results screen: what it is, when, and one-tap actions.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final when = item.due == null
        ? null
        : whenLabel(item.due!, allDay: item.allDay);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.rule),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showItemSheet(context, item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KindDot(item.kind),
                  const SizedBox(width: 7),
                  Text(
                    item.kind.label,
                    style: p.serif(18, italic: true, color: p.faint),
                  ),
                  const Spacer(),
                  if (when != null)
                    Flexible(
                      child: Text(
                        when,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: p.sans(12.5, color: p.faint),
                      ),
                    ),
                  if (item.kind == Kind.task) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 32,
                      height: 28,
                      child: Checkbox(
                        value: item.done,
                        onChanged: (_) => ItemActions(context).toggleDone(item),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                item.text,
                style: p
                    .sans(16, weight: FontWeight.w500, height: 1.3)
                    .copyWith(
                      decoration: item.done ? TextDecoration.lineThrough : null,
                      decorationColor: p.faint,
                      color: item.done ? p.faint : p.ink,
                    ),
              ),
              if (item.details != null) ...[
                const SizedBox(height: 3),
                Text(
                  item.details!,
                  style: p.sans(13.5, color: p.faint, height: 1.35),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: itemPills(context, item),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact item line for the home screen, with its main action as an icon.
class ItemRow extends StatelessWidget {
  const ItemRow({super.key, required this.item});

  final Item item;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final a = ItemActions(context);
    final sub = <String>[
      if (item.hasReminder)
        'Reminds ${whenLabel(item.reminderAt!)}'
      else if (item.due != null)
        whenLabel(item.due!, allDay: item.allDay),
      if (item.inCalendar) 'In calendar',
      if (item.details != null) item.details!,
    ];
    final (IconData icon, String tip, VoidCallback onTap) = switch (item.kind) {
      Kind.task => (
        item.inCalendar ? Icons.event_available_rounded : Icons.event_rounded,
        'Add to calendar',
        () => a.addToCalendar(item),
      ),
      Kind.reminder => (
        item.hasReminder ? Icons.alarm_on_rounded : Icons.alarm_add_rounded,
        item.hasReminder ? 'Change reminder' : 'Set reminder',
        () => a.setReminder(item, pick: item.hasReminder),
      ),
      Kind.note => (Icons.content_copy_rounded, 'Copy', () => a.copy(item)),
      Kind.idea => (Icons.ios_share_rounded, 'Share', () => a.share(item)),
    };

    return Dismissible(
      key: ValueKey('row-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: p.reminder.withValues(alpha: 0.18),
        child: Icon(Icons.delete_outline_rounded, color: p.ink),
      ),
      onDismissed: (_) => a.delete(item),
      child: InkWell(
        onTap: () => showItemSheet(context, item),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
          child: Row(
            children: [
              if (item.kind == Kind.task)
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: item.done,
                    onChanged: (_) => a.toggleDone(item),
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else
                SizedBox(
                  width: 28,
                  child: Center(child: KindDot(item.kind, size: 9)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: p
                          .sans(15.5, height: 1.3)
                          .copyWith(
                            decoration: item.done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: p.faint,
                            color: item.done ? p.faint : p.ink,
                          ),
                    ),
                    if (sub.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          sub.join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: p.sans(12.5, color: p.faint),
                        ),
                      ),
                  ],
                ),
              ),
              if (!item.done)
                IconButton(
                  tooltip: tip,
                  onPressed: onTap,
                  icon: Icon(icon, size: 20, color: p.ink),
                  style: IconButton.styleFrom(
                    backgroundColor: p.kind(item.kind).withValues(alpha: 0.16),
                    minimumSize: const Size(40, 40),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
