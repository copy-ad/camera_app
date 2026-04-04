import 'package:flutter/services.dart';

class SystemActionService {
  static const MethodChannel _channel = MethodChannel('tempcam/system');

  Future<bool> openExternalUrl(String url) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openExternalUrl',
        <String, dynamic>{'url': url},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAddContact({
    required String phoneNumber,
    required String displayName,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openAddContact',
        <String, dynamic>{
          'phoneNumber': phoneNumber,
          'displayName': displayName,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
