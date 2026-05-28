import 'package:clear_translate/application/settings/settings_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_settings_repository.dart';

void main() {
  test('saves provider config and api key separately', () async {
    final repository = FakeSettingsRepository();
    final controller = SettingsController(repository);

    await controller.save(
      baseUrl: 'https://example.com/v1/',
      modelName: 'test-model',
      apiKey: 'secret-key',
      translationStyle: 'formal',
      saveHistoryEnabled: false,
      chunkSize: 2000,
      showWindowHotKey: const {'test': 'show'},
      clearInputHotKey: const {'test': 'clear'},
    );

    expect(
        repository.settings.providerConfig.baseUrl, 'https://example.com/v1');
    expect(repository.settings.providerConfig.modelName, 'test-model');
    expect(repository.settings.translationStyle, 'formal');
    expect(repository.settings.saveHistoryEnabled, isFalse);
    expect(repository.settings.chunkSize, 2000);
    expect(repository.settings.showWindowHotKey, {'test': 'show'});
    expect(repository.settings.clearInputHotKey, {'test': 'clear'});
    expect(repository.apiKey, 'secret-key');
    expect(controller.state.successMessage, '设置已保存');
  });
}
