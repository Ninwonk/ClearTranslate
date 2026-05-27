import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/settings/settings_controller.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelController = TextEditingController();
  final _chunkSizeController = TextEditingController();

  bool _hasBoundState = false;
  bool _saveHistoryEnabled = true;
  String _translationStyle = 'natural';

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _chunkSizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    _bindStateOnce(state);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsSectionTitle('API 设置'),
          TextField(
            controller: _baseUrlController,
            decoration: const InputDecoration(
              labelText: 'API Base URL',
              hintText: 'https://api.openai.com/v1',
              prefixIcon: Icon(Icons.link),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKeyController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'API Key',
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _modelController,
            decoration: const InputDecoration(
              labelText: '模型名称',
              hintText: 'gpt-4o-mini',
              prefixIcon: Icon(Icons.memory),
            ),
          ),
          const SizedBox(height: 24),
          const _SettingsSectionTitle('翻译偏好'),
          DropdownButtonFormField<String>(
            initialValue: _translationStyle,
            decoration: const InputDecoration(
              labelText: '翻译风格',
              prefixIcon: Icon(Icons.tune),
            ),
            items: const [
              DropdownMenuItem(value: 'natural', child: Text('自然')),
              DropdownMenuItem(value: 'accurate', child: Text('准确')),
              DropdownMenuItem(value: 'formal', child: Text('正式')),
              DropdownMenuItem(value: 'concise', child: Text('简洁')),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _translationStyle = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _chunkSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '长文本分段长度',
              prefixIcon: Icon(Icons.segment),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _saveHistoryEnabled,
            title: const Text('保存历史记录'),
            secondary: const Icon(Icons.history),
            onChanged: (value) {
              setState(() => _saveHistoryEnabled = value);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => _saveSettings(context, controller),
            icon: state.isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('保存设置'),
          ),
          if (state.isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          if (state.successMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.successMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  void _bindStateOnce(SettingsState state) {
    if (_hasBoundState || state.isLoading) {
      return;
    }

    final settings = state.settings;
    _baseUrlController.text = settings.providerConfig.baseUrl;
    _apiKeyController.text = state.apiKey;
    _modelController.text = settings.providerConfig.modelName;
    _chunkSizeController.text = settings.chunkSize.toString();
    _saveHistoryEnabled = settings.saveHistoryEnabled;
    _translationStyle = settings.translationStyle;
    _hasBoundState = true;
  }

  Future<void> _saveSettings(
    BuildContext context,
    SettingsController controller,
  ) async {
    final chunkSize = int.tryParse(_chunkSizeController.text.trim()) ?? 3000;

    await controller.save(
      baseUrl: _baseUrlController.text,
      modelName: _modelController.text,
      apiKey: _apiKeyController.text,
      translationStyle: _translationStyle,
      saveHistoryEnabled: _saveHistoryEnabled,
      chunkSize: chunkSize,
    );

    if (!context.mounted) {
      return;
    }

    final state = ref.read(settingsControllerProvider);
    if (state.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.successMessage!)),
      );
    }
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
