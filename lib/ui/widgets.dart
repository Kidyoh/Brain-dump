import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme.dart';

class KindDot extends StatelessWidget {
  const KindDot(this.kind, {super.key, this.size = 8});

  final Kind kind;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Paper.of(context).kind(kind),
      shape: BoxShape.circle,
    ),
  );
}

enum PillStyle {
  /// Ink fill: the thing to do now.
  filled,

  /// Kind-coloured tint: the item's main action.
  tinted,

  /// Hairline outline: a second option.
  outline,
}

/// A one-tap action button, like "Add to calendar".
class ActionPill extends StatelessWidget {
  const ActionPill({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.style = PillStyle.tinted,
    this.tint,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final PillStyle style;
  final Color? tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final fg = style == PillStyle.filled ? p.paper : p.ink;
    final bg = switch (style) {
      PillStyle.filled => p.ink,
      PillStyle.tinted => (tint ?? p.faint).withValues(alpha: 0.18),
      PillStyle.outline => Colors.transparent,
    };
    return Material(
      color: bg,
      shape: StadiumBorder(
        side: style == PillStyle.outline
            ? BorderSide(color: p.rule, width: 1.2)
            : BorderSide.none,
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: p.sans(13, weight: FontWeight.w600, color: fg),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 4), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small round icon button in the paper style.
class PaperIconButton extends StatelessWidget {
  const PaperIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, size: 22, color: p.faint),
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: const CircleBorder(),
      ),
    );
  }
}

const _numberWords = [
  'Nothing', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', //
  'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve',
];

/// "Six things." / "One thing." / "14 things."
String thingsHeadline(int n) {
  final word = n < _numberWords.length ? _numberWords[n] : '$n';
  return n == 1 ? '$word thing.' : '$word things.';
}
