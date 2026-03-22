import 'package:hive/hive.dart';

class PhotoRecord {
  PhotoRecord({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.timerLabel,
    this.expiresAt,
    this.isKeptForever = false,
  });

  final String id;
  final String filePath;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isKeptForever;
  final String timerLabel;

  bool get isExpired {
    if (isKeptForever) {
      return false;
    }
    return expiresAt != null && expiresAt!.isBefore(DateTime.now());
  }

  PhotoRecord copyWith({
    String? filePath,
    DateTime? expiresAt,
    bool? isKeptForever,
    String? timerLabel,
  }) {
    return PhotoRecord(
      id: id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isKeptForever: isKeptForever ?? this.isKeptForever,
      timerLabel: timerLabel ?? this.timerLabel,
    );
  }
}

class PhotoRecordAdapter extends TypeAdapter<PhotoRecord> {
  @override
  final int typeId = 2;

  @override
  PhotoRecord read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < fieldCount; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return PhotoRecord(
      id: fields[0] as String,
      filePath: fields[1] as String,
      createdAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime?,
      isKeptForever: fields[4] as bool,
      timerLabel: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoRecord obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.filePath)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.isKeptForever)
      ..writeByte(5)
      ..write(obj.timerLabel);
  }
}

