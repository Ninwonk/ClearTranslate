import 'package:clear_translate/domain/entities/app_settings.dart';
import 'package:clear_translate/domain/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({
    AppSettings? initialSettings,
    String initialApiKey = '',
  })  : settings = initialSettings ?? AppSettings.defaults(),
        apiKey = initialApiKey;

  AppSettings settings;
  String apiKey;

  @override
  Future<AppSettings> load() async => settings;

  @override
  Future<String?> readApiKey(String storageKey) async {
    return apiKey.isEmpty ? null : apiKey;
  }

  @override
  Future<void> save(AppSettings settings) async {
    this.settings = settings;
  }

  @override
  Future<void> writeApiKey(String storageKey, String apiKey) async {
    this.apiKey = apiKey;
  }
}
