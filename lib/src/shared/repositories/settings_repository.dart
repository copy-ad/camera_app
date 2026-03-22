import 'package:hive/hive.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  final Box<AppSettings> _box;
  static const _settingsKey = 'app_settings';

  AppSettings read() {
    return _box.get(_settingsKey) ?? AppSettings.defaults();
  }

  Future<void> save(AppSettings settings) async {
    await _box.put(_settingsKey, settings);
  }
}

