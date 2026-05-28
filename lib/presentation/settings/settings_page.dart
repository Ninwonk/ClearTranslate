import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../application/settings/settings_controller.dart';
import '../../shared/desktop/desktop_hotkeys.dart';
import '../../shared/desktop/desktop_integration.dart';

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
  final _glossaryController = TextEditingController();

  bool _hasBoundState = false;
  bool _saveHistoryEnabled = true;
  String _translationStyle = 'natural';
  HotKey? _showWindowHotKey;
  HotKey? _clearInputHotKey;

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _chunkSizeController.dispose();
    _glossaryController.dispose();
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
          TextField(
            controller: _glossaryController,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: '术语表 / 长文本术语提示',
              hintText:
                  'ClearTranslate = ClearTranslate\nlocal dictionary = 本地词典',
              prefixIcon: Icon(Icons.article_outlined),
              alignLabelWithHint: true,
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
          const _SettingsSectionTitle('桌面快捷键'),
          _HotKeySettingTile(
            title: '唤出翻译界面',
            hotKey: _showWindowHotKey,
            onRecord: () async {
              final hotKey = await _recordHotKey(
                context,
                title: '录制唤出翻译界面快捷键',
                initialHotKey: _showWindowHotKey,
              );
              if (hotKey != null) {
                setState(() => _showWindowHotKey = hotKey);
              }
            },
            onReset: () {
              setState(
                  () => _showWindowHotKey = DesktopHotKeys.defaultShowWindow());
            },
          ),
          const SizedBox(height: 8),
          _HotKeySettingTile(
            title: '清空输入区',
            hotKey: _clearInputHotKey,
            onRecord: () async {
              final hotKey = await _recordHotKey(
                context,
                title: '录制清空输入区快捷键',
                initialHotKey: _clearInputHotKey,
              );
              if (hotKey != null) {
                setState(() => _clearInputHotKey = hotKey);
              }
            },
            onReset: () {
              setState(
                  () => _clearInputHotKey = DesktopHotKeys.defaultClearInput());
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
    _glossaryController.text = settings.glossary;
    _saveHistoryEnabled = settings.saveHistoryEnabled;
    _translationStyle = settings.translationStyle;
    _showWindowHotKey = DesktopHotKeys.showWindow(settings);
    _clearInputHotKey = DesktopHotKeys.clearInput(settings);
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
      glossary: _glossaryController.text,
      showWindowHotKey: _showWindowHotKey == null
          ? null
          : DesktopHotKeys.toJson(_showWindowHotKey!),
      clearInputHotKey: _clearInputHotKey == null
          ? null
          : DesktopHotKeys.toJson(_clearInputHotKey!),
    );

    if (!context.mounted) {
      return;
    }

    final state = ref.read(settingsControllerProvider);
    if (state.successMessage != null) {
      await DesktopIntegration.instance.configureHotKeys(state.settings);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.successMessage!)),
      );
    }
  }

  Future<HotKey?> _recordHotKey(
    BuildContext context, {
    required String title,
    required HotKey? initialHotKey,
  }) {
    HotKey? recordedHotKey = initialHotKey;

    return showDialog<HotKey>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasModifier =
                (recordedHotKey?.modifiers ?? const <HotKeyModifier>[])
                    .isNotEmpty;
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('按下新的组合键。建议至少包含 Ctrl/Cmd、Alt 或 Shift。'),
                  const SizedBox(height: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: HotKeyRecorder(
                        initalHotKey: recordedHotKey,
                        onHotKeyRecorded: (hotKey) {
                          recordedHotKey = HotKey(
                            key: hotKey.key,
                            modifiers: hotKey.modifiers,
                            scope: HotKeyScope.system,
                          );
                          setDialogState(() {});
                        },
                      ),
                    ),
                  ),
                  if (!hasModifier) ...[
                    const SizedBox(height: 12),
                    Text(
                      '请录制包含修饰键的组合键。',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: recordedHotKey == null || !hasModifier
                      ? null
                      : () => Navigator.of(context).pop(recordedHotKey),
                  child: const Text('使用此快捷键'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _HotKeySettingTile extends StatelessWidget {
  const _HotKeySettingTile({
    required this.title,
    required this.hotKey,
    required this.onRecord,
    required this.onReset,
  });

  final String title;
  final HotKey? hotKey;
  final VoidCallback onRecord;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.keyboard_command_key),
      title: Text(title),
      subtitle: Text(
        hotKey == null ? '未设置' : DesktopHotKeys.label(hotKey!),
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: onRecord,
            child: const Text('录制'),
          ),
          TextButton(
            onPressed: onReset,
            child: const Text('默认'),
          ),
        ],
      ),
    );
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
