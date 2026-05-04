import 'dart:io';
import 'dart:ui' as ui;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

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
  static final RegExp _phoneCandidatePattern = RegExp(
    r'(?<![A-Z0-9])(?:\+|00)?(?:\d[\s().\-]*){7,16}(?![A-Z0-9])',
    caseSensitive: false,
  );
  static final RegExp _numericNoisePattern = RegExp(
    r'\b(?:order|invoice|receipt|ticket|tracking|track|ref|reference|id|auth|code|serial|sku|tax|vat|iban|account|card|date|time|total|amount|qty|quantity|zip|postal)\b',
    caseSensitive: false,
  );
  static final RegExp _dateLikePattern = RegExp(
    r'\b\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}\b',
  );
  static final RegExp _repeatedDigitPattern = RegExp(r'^(\d)\1{6,}$');
  static final RegExp _streetNumberPattern = RegExp(
    r"\b\d{1,6}\s+[a-z][a-z0-9.']*(?:\s+[a-z][a-z0-9.']*){0,5}\s+(?:street|st|road|rd|avenue|ave|boulevard|blvd|drive|dr|lane|ln|court|ct|way|place|pl|square|sq|highway|hwy|parkway|pkwy|circle|cir|terrace|ter|trail|trl|cadde|cd|caddesi|sokak|sk|sokagi|bulvar|bulvari)\b",
    caseSensitive: false,
  );
  static final RegExp _streetKeywordPattern = RegExp(
    r'\b(?:street|st|road|rd|avenue|ave|boulevard|blvd|drive|dr|lane|ln|court|ct|way|place|pl|square|sq|highway|hwy|parkway|pkwy|circle|cir|terrace|ter|trail|trl|cadde|cd|caddesi|sokak|sk|sokagi|bulvar|bulvari)\b',
    caseSensitive: false,
  );
  static final RegExp _unitPattern = RegExp(
    r'\b(?:suite|ste|floor|fl|apartment|apt|unit|building|bldg|no|numara|daire|kat)\b\s*[:#-]?\s*[a-z0-9-]+',
    caseSensitive: false,
  );
  static final RegExp _postalPattern = RegExp(
    r'\b(?:[A-Z]\d[A-Z]\s?\d[A-Z]\d|\d{5}(?:-\d{4})?|\d{4,6})\b',
    caseSensitive: false,
  );
  static final RegExp _cityRegionPattern = RegExp(
    r"\b[A-Z][a-zA-Z.']+(?:\s+[A-Z][a-zA-Z.']+){0,2},?\s+(?:[A-Z]{2}|[A-Z][a-zA-Z.']{2,})\b",
  );
  static final RegExp _addressLabelPattern = RegExp(
    r'\b(?:address|addr|location|ship to|billing address|delivery address|adres)\b',
    caseSensitive: false,
  );
  static final RegExp _addressNoisePattern = RegExp(
    r'\b(?:subtotal|total|amount|invoice|receipt|order|tracking|tax|vat|paid|cash|change|qty|quantity|description|item|sku|barcode|serial|password|username|email|website|www|http|terms|expires|valid|card|iban)\b',
    caseSensitive: false,
  );

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
    final blocks = recognized.blocks
        .map(_OcrBlock.fromTextBlock)
        .where((block) => block.lines.isNotEmpty)
        .toList(growable: false);
    final lines = blocks.expand((block) => block.lines).toList(growable: false);

    return DocumentScanResult(
      phoneNumbers: _extractPhoneNumbers(lines),
      addresses: _extractAddresses(blocks),
    );
  }

  List<String> _extractPhoneNumbers(List<_OcrLine> lines) {
    final candidates = <_PhoneCandidate>[];

    for (final line in lines) {
      final text = _cleanOcrText(line.text);
      if (_numericNoisePattern.hasMatch(text) ||
          _dateLikePattern.hasMatch(text)) {
        continue;
      }
      for (final match in _phoneCandidatePattern.allMatches(text)) {
        final raw = match.group(0)?.trim();
        if (raw == null || raw.isEmpty) {
          continue;
        }
        final candidate = _validatePhoneCandidate(raw, text);
        if (candidate != null) {
          candidates.add(candidate);
        }
      }
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    final output = <String>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      if (seen.add(candidate.normalized)) {
        output.add(candidate.display);
      }
      if (output.length == 2) {
        break;
      }
    }
    return output;
  }

  _PhoneCandidate? _validatePhoneCandidate(String raw, String sourceLine) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) {
      return null;
    }
    if (_repeatedDigitPattern.hasMatch(digits)) {
      return null;
    }
    if (!raw.contains('+') &&
        !raw.contains('00') &&
        !RegExp(r'[\s().-]').hasMatch(raw)) {
      return null;
    }
    if (_looksLikeNumericIdentifier(raw, sourceLine)) {
      return null;
    }

    final regions = _preferredPhoneRegions();
    PhoneNumber? parsed;
    for (final region in regions) {
      try {
        final candidate = PhoneNumber.parse(
          raw,
          callerCountry: region,
          destinationCountry: region,
        );
        if (candidate.isValid()) {
          parsed = candidate;
          break;
        }
      } catch (_) {}
    }
    if (parsed == null) {
      return null;
    }

    var score = 8;
    if (raw.trim().startsWith('+')) {
      score += 2;
    }
    if (RegExp(r'[\s().-]').hasMatch(raw)) {
      score += 1;
    }
    if (RegExp(
      r'\b(?:tel|phone|mobile|cell|call|gsm|telefon|iletisim|contact)\b',
      caseSensitive: false,
    ).hasMatch(sourceLine)) {
      score += 2;
    }

    return _PhoneCandidate(
      normalized: parsed.international,
      display: parsed.international,
      score: score,
    );
  }

  bool _looksLikeNumericIdentifier(String raw, String sourceLine) {
    final compact = raw.replaceAll(RegExp(r'\s+'), '');
    final digits = compact.replaceAll(RegExp(r'\D'), '');
    if (_numericNoisePattern.hasMatch(sourceLine)) {
      return true;
    }
    if (_dateLikePattern.hasMatch(raw)) {
      return true;
    }
    if (RegExp(r'^[A-Z]{1,6}[-:]?\d{4,}$', caseSensitive: false)
        .hasMatch(compact)) {
      return true;
    }
    if (!raw.trim().startsWith('+') &&
        RegExp(r'^\d{4,6}[-/]\d{2,6}[-/]\d{2,6}$').hasMatch(compact)) {
      return true;
    }
    return digits.length > 11 &&
        !raw.trim().startsWith('+') &&
        !raw.contains('00');
  }

  List<String> _extractAddresses(List<_OcrBlock> blocks) {
    final candidates = <_AddressCandidate>[];

    for (final block in blocks) {
      final lines = block.lines;
      for (var start = 0; start < lines.length; start++) {
        for (var length = 1;
            length <= 3 && start + length <= lines.length;
            length++) {
          final window = lines
              .skip(start)
              .take(length)
              .map((line) => _cleanOcrText(line.text))
              .where((line) => line.isNotEmpty)
              .toList(growable: false);
          if (window.isEmpty) {
            continue;
          }
          final candidate = _scoreAddressWindow(window);
          if (candidate != null) {
            candidates.add(candidate);
          }
        }
      }
    }

    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) {
        return score;
      }
      return a.display.length.compareTo(b.display.length);
    });

    final output = <String>[];
    final seen = <String>{};
    for (final candidate in candidates) {
      if (seen.any(
        (item) =>
            item.contains(candidate.normalized) ||
            candidate.normalized.contains(item),
      )) {
        continue;
      }
      seen.add(candidate.normalized);
      output.add(candidate.display);
      if (output.length == 1) {
        break;
      }
    }
    return output;
  }

  _AddressCandidate? _scoreAddressWindow(List<String> lines) {
    final joined = lines.join(', ');
    final normalized = _normalizeAddress(joined);
    if (normalized.length < 14 || normalized.length > 180) {
      return null;
    }
    if (_addressNoisePattern.hasMatch(joined)) {
      return null;
    }
    if (RegExp(r'@|https?://|www\.', caseSensitive: false).hasMatch(joined)) {
      return null;
    }

    final digitCount = RegExp(r'\d').allMatches(joined).length;
    final letterCount = RegExp(r'[A-Za-z]').allMatches(joined).length;
    if (digitCount == 0 || letterCount < 6) {
      return null;
    }

    var score = 0;
    var signals = 0;

    if (_streetNumberPattern.hasMatch(joined)) {
      score += 5;
      signals += 2;
    } else if (_streetKeywordPattern.hasMatch(joined) &&
        RegExp(r'\b\d{1,6}\b').hasMatch(joined)) {
      score += 3;
      signals += 1;
    }

    if (_unitPattern.hasMatch(joined)) {
      score += 2;
      signals += 1;
    }
    if (_postalPattern.hasMatch(joined) && _hasNearbyPlaceText(joined)) {
      score += 2;
      signals += 1;
    }
    if (_cityRegionPattern.hasMatch(joined)) {
      score += 2;
      signals += 1;
    }
    if (_addressLabelPattern.hasMatch(joined)) {
      score += 1;
    }
    if (lines.length > 1) {
      score += 1;
      signals += 1;
    }
    if (_hasMostlyNumericLine(lines)) {
      score -= 3;
    }
    if (_looksLikeSentence(joined)) {
      score -= 2;
    }

    if (signals < 2 || score < 6) {
      return null;
    }

    return _AddressCandidate(
      normalized: normalized,
      display: _formatAddress(lines),
      score: score,
    );
  }

  bool _hasNearbyPlaceText(String value) {
    return RegExp(
      r"\b[A-Z][a-zA-Z.']{2,}(?:\s+[A-Z][a-zA-Z.']{2,}){0,2}\b",
    ).hasMatch(value);
  }

  bool _hasMostlyNumericLine(List<String> lines) {
    return lines.any((line) {
      final compact = line.replaceAll(RegExp(r'\s+'), '');
      if (compact.length < 5) {
        return false;
      }
      final digits = RegExp(r'\d').allMatches(compact).length;
      return digits / compact.length > 0.65;
    });
  }

  bool _looksLikeSentence(String value) {
    final words =
        value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
    return words > 14 && !_streetNumberPattern.hasMatch(value);
  }

  List<IsoCode> _preferredPhoneRegions() {
    final countryCode = ui.PlatformDispatcher.instance.locale.countryCode;
    final regions = <IsoCode>[];
    if (countryCode != null && countryCode.length == 2) {
      try {
        regions.add(IsoCode.fromJson(countryCode.toUpperCase()));
      } catch (_) {}
    }
    for (final region in const [
      IsoCode.US,
      IsoCode.TR,
      IsoCode.GB,
      IsoCode.DE,
      IsoCode.FR,
    ]) {
      if (!regions.contains(region)) {
        regions.add(region);
      }
    }
    return regions;
  }

  String _cleanOcrText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeAddress(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  String _formatAddress(List<String> lines) {
    return lines
        .map((line) => line.trim().replaceAll(RegExp(r'\s+'), ' '))
        .where((line) => line.isNotEmpty)
        .join(', ');
  }
}

class _OcrBlock {
  const _OcrBlock(this.lines);

  final List<_OcrLine> lines;

  static _OcrBlock fromTextBlock(TextBlock block) {
    return _OcrBlock(
      block.lines
          .map((line) => _OcrLine(line.text.trim()))
          .where((line) => line.text.isNotEmpty)
          .toList(growable: false),
    );
  }
}

class _OcrLine {
  const _OcrLine(this.text);

  final String text;
}

class _PhoneCandidate {
  const _PhoneCandidate({
    required this.normalized,
    required this.display,
    required this.score,
  });

  final String normalized;
  final String display;
  final int score;
}

class _AddressCandidate {
  const _AddressCandidate({
    required this.normalized,
    required this.display,
    required this.score,
  });

  final String normalized;
  final String display;
  final int score;
}
