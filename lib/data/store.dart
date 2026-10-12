import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// All your dumps, newest first, saved on the phone.
class DumpStore extends ChangeNotifier {
  DumpStore(this._prefs);

  final SharedPreferences _prefs;
  final List<Dump> _dumps = [];

  static const _key = 'dumps';

  List<Dump> get dumps => List.unmodifiable(_dumps);

  /// Every item across all dumps, newest dump first.
  Iterable<Item> get items => _dumps.expand((d) => d.items);

  Iterable<Item> get openItems => items.where((i) => !i.done);

  int openCount(Kind k) => openItems.where((i) => i.kind == k).length;

  /// Open items with a time coming up (or just passed), soonest first.
  List<Item> upNext(DateTime now) {
    final cutoff = now.subtract(const Duration(hours: 12));
    return openItems
        .where((i) => i.due != null && i.due!.isAfter(cutoff))
        .toList()
      ..sort((a, b) => a.due!.compareTo(b.due!));
  }

  void load() {
    _dumps.clear();
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      for (final d in jsonDecode(raw) as List) {
        _dumps.add(Dump.fromJson((d as Map).cast<String, Object?>()));
      }
    } catch (e) {
      debugPrint('Could not read saved dumps: $e');
    }
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
      _key,
      jsonEncode([for (final d in _dumps) d.toJson()]),
    );
  }

  Dump? dumpOf(Item item) {
    for (final d in _dumps) {
      if (d.items.contains(item)) return d;
    }
    return null;
  }

  Future<void> add(Dump dump) {
    _dumps.insert(0, dump);
    return _save();
  }

  /// Saves changes made to an item or dump in place.
  Future<void> changed() => _save();

  /// Removes [item] and returns a function that puts it back.
  Future<VoidCallback> removeItem(Item item) async {
    final dump = dumpOf(item);
    if (dump == null) return () {};
    final index = dump.items.indexOf(item);
    dump.items.removeAt(index);
    await _save();
    return () {
      dump.items.insert(index.clamp(0, dump.items.length), item);
      _save();
    };
  }

  Future<VoidCallback> removeDump(Dump dump) async {
    final index = _dumps.indexOf(dump);
    if (index < 0) return () {};
    _dumps.removeAt(index);
    await _save();
    return () {
      _dumps.insert(index.clamp(0, _dumps.length), dump);
      _save();
    };
  }

  Future<void> clear() async {
    _dumps.clear();
    await _save();
  }

  /// A fresh id for a reminder notification.
  int nextNotificationId() {
    final id = (_prefs.getInt('nextNid') ?? 1);
    _prefs.setInt('nextNid', id + 1);
    return id;
  }
}
