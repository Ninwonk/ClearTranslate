import '../entities/app_settings.dart';

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);

  Future<String?> readApiKey(String storageKey);

  Future<void> writeApiKey(String storageKey, String apiKey);
}
