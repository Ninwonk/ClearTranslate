import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/translate/translate_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(translateControllerProvider);
    final controller = ref.read(translateControllerProvider.notifier);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.enter):
            const _TranslateIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.enter):
            const _TranslateIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const _CancelIntent(),
      },
      child: Actions(
        actions: {
          _TranslateIntent: CallbackAction<_TranslateIntent>(
            onInvoke: (_) => _translate(controller),
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) => controller.cancel(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('ClearTranslate'),
              actions: [
                IconButton(
                  tooltip: '清空',
                  onPressed: () => _clear(controller),
                  icon: const Icon(Icons.clear),
                ),
                IconButton(
                  tooltip: '复制译文',
                  onPressed: state.outputText.isEmpty
                      ? null
                      : () => _copyResult(context, state.outputText),
                  icon: const Icon(Icons.content_copy),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _LanguageBar(
                    sourceLabel: state.sourceLanguageLabel,
                    targetLabel: state.targetLanguageLabel,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 760;
                        final inputPanel = _TextPanel(
                          title: '输入',
                          child: TextField(
                            controller: _inputController,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: '粘贴或输入要翻译的文本...',
                              border: InputBorder.none,
                            ),
                          ),
                        );
                        final outputPanel = _TextPanel(
                          title: '译文',
                          child: SelectableText(
                            state.outputText.isEmpty
                                ? '翻译结果会显示在这里'
                                : state.outputText,
                          ),
                        );

                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(child: inputPanel),
                              const SizedBox(width: 12),
                              Expanded(child: outputPanel),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            Expanded(child: inputPanel),
                            const SizedBox(height: 12),
                            Expanded(child: outputPanel),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionBar(
                    isLoading: state.isLoading,
                    hasOutput: state.outputText.isNotEmpty,
                    onTranslate: () => _translate(controller),
                    onClear: () => _clear(controller),
                    onCancel: controller.cancel,
                    onCopy: () => _copyResult(context, state.outputText),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _translate(TranslateController controller) {
    controller.translate(_inputController.text);
  }

  void _clear(TranslateController controller) {
    _inputController.clear();
    controller.clear();
  }

  Future<void> _copyResult(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制译文')),
    );
  }
}

class _LanguageBar extends StatelessWidget {
  const _LanguageBar({
    required this.sourceLabel,
    required this.targetLabel,
  });

  final String sourceLabel;
  final String targetLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Chip(label: Text(sourceLabel)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward),
        ),
        Chip(label: Text(targetLabel)),
      ],
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isLoading,
    required this.hasOutput,
    required this.onTranslate,
    required this.onClear,
    required this.onCancel,
    required this.onCopy,
  });

  final bool isLoading;
  final bool hasOutput;
  final VoidCallback onTranslate;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FilledButton.icon(
          onPressed: isLoading ? null : onTranslate,
          icon: const Icon(Icons.translate),
          label: const Text('翻译'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: onClear,
          icon: const Icon(Icons.clear),
          label: const Text('清空'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: hasOutput ? onCopy : null,
          icon: const Icon(Icons.content_copy),
          label: const Text('复制'),
        ),
        const Spacer(),
        if (isLoading)
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.stop),
            label: const Text('取消'),
          ),
      ],
    );
  }
}

class _TranslateIntent extends Intent {
  const _TranslateIntent();
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}

