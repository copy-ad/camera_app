import 'package:hive/hive.dart';

enum VaultHistoryEventType {
  exported,
  deleted,
  autoDeleted,
}

class VaultHistoryEntry {
  VaultHistoryEntry({
    required this.id,
    required this.eventType,
    required this.title,
    required this.details,
    required this.occurredAt,
  });

  final String id;
  final VaultHistoryEventType eventType;
  final String title;
  final String details;
  final DateTime occurredAt;
}

class VaultHistoryEventTypeAdapter extends TypeAdapter<VaultHistoryEventType> {
  @override
  final int typeId = 4;

  @override
  VaultHistoryEventType read(BinaryReader reader) {
    return VaultHistoryEventType.values[reader.readByte()];
  }

  @override
  void write(BinaryWriter writer, VaultHistoryEventType obj) {
    writer.writeByte(obj.index);
  }
}

class VaultHistoryEntryAdapter extends TypeAdapter<VaultHistoryEntry> {
  @override
  final int typeId = 5;

  @override
  VaultHistoryEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return VaultHistoryEntry(
      id: fields[0] as String,
      eventType: fields[1] as VaultHistoryEventType,
      title: fields[2] as String,
      details: fields[3] as String,
      occurredAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, VaultHistoryEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.eventType)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.occurredAt);
  }
}
