import 'package:hive/hive.dart';

enum MediaType { photo, video }

class PhotoRecord {
  PhotoRecord({
    required this.id,
    required this.filePath,
    required this.createdAt,
    required this.timerLabel,
    this.expiresAt,
    this.isKeptForever = false,
    this.mediaType = MediaType.photo,
    this.detectedPhoneNumbers = const [],
    this.detectedAddresses = const [],
    this.smartScanCompletedAt,
  });

  final String id;
  final String filePath;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isKeptForever;
  final String timerLabel;
  final MediaType mediaType;
  final List<String> detectedPhoneNumbers;
  final List<String> detectedAddresses;
  final DateTime? smartScanCompletedAt;

  bool get isExpired {
    if (isKeptForever) {
      return false;
    }
    return expiresAt != null && expiresAt!.isBefore(DateTime.now());
  }

  bool get isVideo => mediaType == MediaType.video;
  bool get isPhoto => mediaType == MediaType.photo;
  bool get hasDetectedDetails =>
      detectedPhoneNumbers.isNotEmpty || detectedAddresses.isNotEmpty;
  bool get hasCompletedSmartScan => smartScanCompletedAt != null;

  PhotoRecord copyWith({
    String? filePath,
    DateTime? expiresAt,
    bool? isKeptForever,
    String? timerLabel,
    MediaType? mediaType,
    List<String>? detectedPhoneNumbers,
    List<String>? detectedAddresses,
    DateTime? smartScanCompletedAt,
  }) {
    return PhotoRecord(
      id: id,
      filePath: filePath ?? this.filePath,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isKeptForever: isKeptForever ?? this.isKeptForever,
      timerLabel: timerLabel ?? this.timerLabel,
      mediaType: mediaType ?? this.mediaType,
      detectedPhoneNumbers: detectedPhoneNumbers ?? this.detectedPhoneNumbers,
      detectedAddresses: detectedAddresses ?? this.detectedAddresses,
      smartScanCompletedAt: smartScanCompletedAt ?? this.smartScanCompletedAt,
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
      mediaType: MediaType.values.byName((fields[6] as String?) ?? 'photo'),
      detectedPhoneNumbers:
          (fields[7] as List?)?.map((item) => item.toString()).toList() ??
              const [],
      detectedAddresses:
          (fields[8] as List?)?.map((item) => item.toString()).toList() ??
              const [],
      smartScanCompletedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PhotoRecord obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.timerLabel)
      ..writeByte(6)
      ..write(obj.mediaType.name)
      ..writeByte(7)
      ..write(obj.detectedPhoneNumbers)
      ..writeByte(8)
      ..write(obj.detectedAddresses)
      ..writeByte(9)
      ..write(obj.smartScanCompletedAt);
  }
}
