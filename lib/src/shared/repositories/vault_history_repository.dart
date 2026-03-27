import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/vault_history_entry.dart';

class VaultHistoryRepository {
  VaultHistoryRepository(this._box);

  final Box<VaultHistoryEntry> _box;
  final Uuid _uuid = const Uuid();

  static const int _maxEntries = 60;

  List<VaultHistoryEntry> readRecent({int limit = 12}) {
    final items = _box.values.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (items.length <= limit) {
      return items;
    }
    return items.take(limit).toList(growable: false);
  }

  Future<void> add({
    required VaultHistoryEventType eventType,
    required String title,
    required String details,
  }) async {
    final entry = VaultHistoryEntry(
      id: _uuid.v4(),
      eventType: eventType,
      title: title,
      details: details,
      occurredAt: DateTime.now(),
    );
    await _box.put(entry.id, entry);
    await _trimIfNeeded();
  }

  Future<void> _trimIfNeeded() async {
    final items = _box.values.toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (items.length <= _maxEntries) {
      return;
    }
    final idsToDelete = items
        .skip(_maxEntries)
        .map((entry) => entry.id)
        .toList(growable: false);
    await _box.deleteAll(idsToDelete);
  }
}
