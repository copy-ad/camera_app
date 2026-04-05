import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class DocumentScanResult {
  const DocumentScanResult({
    required this.phoneNumbers,
    required this.addresses,
  });

  final List<String> phoneNumbers;
  final List<String> addresses;

  bool get hasData => phoneNumbers.isNotEmpty || addresses.isNotEmpty;
}

class DocumentScanService {
  static final RegExp _phonePattern = RegExp(
    r'(?:(?:\+|00)\d{1,3}[\s\-\.]*)?(?:\(?\d{2,4}\)?[\s\-\.]*){2,5}\d{2,4}',
  );

  static const List<String> _addressKeywords = [
    'address',
    'street',
    'st',
    'road',
    'rd',
    'avenue',
    'ave',
    'boulevard',
    'blvd',
    'drive',
    'dr',
    'lane',
    'ln',
    'court',
    'ct',
    'way',
    'place',
    'pl',
    'square',
    'sq',
    'highway',
    'hwy',
    'building',
    'suite',
    'ste',
    'floor',
    'fl',
    'apartment',
    'apt',
    'unit',
    'no',
    'cadde',
    'cd',
    'sokak',
    'sk',
    'mahalle',
    'mah',
    'bulvari',
    'bulvar',
    'apt no',
    'posta',
    'post',
    'zip',
    'postal',
  ];

  Future<DocumentScanResult> scanPhoto(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const DocumentScanResult(phoneNumbers: [], addresses: []);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final image = InputImage.fromFilePath(filePath);
      return await _processInputImage(image, recognizer);
    } catch (_) {
      return const DocumentScanResult(phoneNumbers: [], addresses: []);
    } finally {
      await recognizer.close();
    }
  }

  Future<DocumentScanResult> scanInputImage(InputImage inputImage) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      return await _processInputImage(inputImage, recognizer);
    } catch (_) {
      return const DocumentScanResult(phoneNumbers: [], addresses: []);
    } finally {
      await recognizer.close();
    }
  }

  Future<DocumentScanResult> _processInputImage(
    InputImage inputImage,
    TextRecognizer recognizer,
  ) async {
    final recognized = await recognizer.processImage(inputImage);
    final lines = recognized.blocks
        .expand((block) => block.lines)
        .map((line) => line.text.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    return DocumentScanResult(
      phoneNumbers: _extractPhoneNumbers(lines),
      addresses: _extractAddresses(lines),
    );
  }

  List<String> _extractPhoneNumbers(List<String> lines) {
    final matches = <String>[];
    final seen = <String>{};

    for (final line in lines) {
      for (final match in _phonePattern.allMatches(line)) {
        final raw = match.group(0)?.trim();
        if (raw == null || raw.isEmpty) {
          continue;
        }

        final normalized = _normalizePhoneNumber(raw);
        if (normalized == null || !seen.add(normalized)) {
          continue;
        }

        matches.add(_prettifyPhoneNumber(raw));
      }
    }

    return matches.take(3).toList(growable: false);
  }

  List<String> _extractAddresses(List<String> lines) {
    final matches = <String>[];
    final seen = <String>{};

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      if (!_looksLikeAddressLine(line)) {
        continue;
      }

      var candidate = line;
      if (index + 1 < lines.length &&
          _looksLikeAddressContinuation(lines[index + 1])) {
        candidate = '$candidate, ${lines[index + 1]}';
      }

      final normalized = _normalizeAddress(candidate);
      if (normalized.length < 10 || !seen.add(normalized)) {
        continue;
      }
      matches.add(candidate);
    }

    return matches.take(3).toList(growable: false);
  }

  String? _normalizePhoneNumber(String value) {
    final trimmed = value.trim();
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      return null;
    }

    final hasPhoneShape = trimmed.contains('+') ||
        trimmed.contains('(') ||
        trimmed.contains(')') ||
        trimmed.contains('-') ||
        trimmed.contains(' ') ||
        trimmed.contains('.');

    if (!hasPhoneShape && digitsOnly.length < 10) {
      return null;
    }

    return trimmed.startsWith('+') ? '+$digitsOnly' : digitsOnly;
  }

  String _prettifyPhoneNumber(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _looksLikeAddressLine(String value) {
    final lower = value.toLowerCase();
    final hasKeyword = _addressKeywords.any(
      (keyword) => lower.contains(keyword),
    );
    final hasStreetNumber = RegExp(r'\d').hasMatch(value);
    return hasKeyword && (hasStreetNumber || lower.contains('address'));
  }

  bool _looksLikeAddressContinuation(String value) {
    final lower = value.toLowerCase();
    return RegExp(r'\d').hasMatch(value) ||
        lower.contains(',') ||
        lower.contains('city') ||
        lower.contains('state') ||
        lower.contains('country') ||
        lower.contains('district') ||
        lower.contains('province') ||
        lower.contains('zip') ||
        lower.contains('postal');
  }

  String _normalizeAddress(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}
