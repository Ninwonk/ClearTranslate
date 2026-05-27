import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository({
    FlutterSecureStorage? secureStorage,
    Directory? settingsDirectory,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _settingsDirectory = settingsDirectory;

  static const _settingsFileName = 'settings.json';

  final FlutterSecureStorage _secureStorage;
  final Directory? _settingsDirectory;

  @override
  Future<AppSettings> load() async {
    final file = await _settingsFile();
    if (!await file.exists()) {
      return AppSettings.defaults();
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return AppSettings.defaults();
    }

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, Object?>) {
      return AppSettings.defaults();
    }

    return AppSettings.fromJson(decoded);
  }

  @override
  Future<void> save(AppSettings settings) async {
    final file = await _settingsFile();
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(settings.toJson()));
  }

  @override
  Future<String?> readApiKey(String storageKey) {
    return _secureStorage.read(key: storageKey);
  }

  @override
  Future<void> writeApiKey(String storageKey, String apiKey) {
    return _secureStorage.write(key: storageKey, value: apiKey);
  }

  Future<File> _settingsFile() async {
    final directory =
        _settingsDirectory ?? await getApplicationSupportDirectory();
    return File(p.join(directory.path, _settingsFileName));
  }
}
