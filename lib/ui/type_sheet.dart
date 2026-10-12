import 'package:flutter/material.dart';

import '../theme.dart';
import 'scope.dart';

/// For when you can't talk out loud: type the ramble and sort it the same way.
Future<void> showTypeSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => const _TypeSheet(),
);

class _TypeSheet extends StatefulWidget {
  const _TypeSheet();

  @override
  State<_TypeSheet> createState() => _TypeSheetState();
}

class _TypeSheetState extends State<_TypeSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    final capture = Scope.of(context).capture;
    Navigator.pop(context);
    capture.submitText(text);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        0,
        22,
        MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Type it out', style: p.serif(32)),
          const SizedBox(height: 4),
          Text(
            'Write it the way you’d say it. No need to tidy up.',
            style: p.sans(14, color: p.faint),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _text,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            style: p.serif(22).copyWith(height: 1.25),
            decoration: const InputDecoration(
              hintText: 'Need to call the dentist, buy batteries…',
            ),
          ),
          const SizedBox(height: 14),
          ListenableBuilder(
            listenable: _text,
            builder: (context, _) => SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _text.text.trim().isEmpty ? null : _submit,
                child: const Text('Sort it'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
