import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _SettingsSectionTitle('API 设置'),
          ListTile(
            leading: Icon(Icons.hub_outlined),
            title: Text('Provider'),
            subtitle: Text('OpenAI-compatible'),
          ),
          ListTile(
            leading: Icon(Icons.link),
            title: Text('API Base URL'),
            subtitle: Text('后续支持配置'),
          ),
          ListTile(
            leading: Icon(Icons.key),
            title: Text('API Key'),
            subtitle: Text('后续使用安全存储保存'),
          ),
          SizedBox(height: 16),
          _SettingsSectionTitle('翻译偏好'),
          ListTile(
            leading: Icon(Icons.language),
            title: Text('默认目标语言'),
            subtitle: Text('自动选择中文或英文'),
          ),
          ListTile(
            leading: Icon(Icons.tune),
            title: Text('翻译风格'),
            subtitle: Text('自然'),
          ),
          SizedBox(height: 16),
          _SettingsSectionTitle('外观'),
          ListTile(
            leading: Icon(Icons.dark_mode_outlined),
            title: Text('主题'),
            subtitle: Text('跟随系统'),
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

