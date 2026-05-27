import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/history/history_controller.dart';
import '../../domain/entities/history_record.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyControllerProvider);
    final controller = ref.read(historyControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('历史'),
        actions: [
          IconButton(
            tooltip: '刷新',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: '清空历史',
            onPressed: state.records.isEmpty
                ? null
                : () => _confirmClear(context, controller),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: _HistoryBody(
        state: state,
        onCopy: (text) => _copy(context, text),
        onDelete: controller.delete,
      ),
    );
  }

  Future<void> _copy(BuildContext context, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制历史译文')),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    HistoryController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空历史记录'),
          content: const Text('此操作只会清空本地历史记录。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await controller.clear();
    }
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.state,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryState state;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    if (state.records.isEmpty) {
      return const Center(child: Text('暂无历史记录'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = state.records[index];
        return _HistoryRecordTile(
          record: record,
          onCopy: () => onCopy(record.outputText),
          onDelete: () => onDelete(record.id),
        );
      },
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({
    required this.record,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryRecord record;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${record.sourceLanguage.label} -> ${record.targetLanguage.label}',
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                Text(
                  _formatTime(record.createdAt),
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.inputText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              record.outputText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (record.model != null)
                  Text(
                    record.model!,
                    style: theme.textTheme.labelSmall,
                  ),
                const Spacer(),
                IconButton(
                  tooltip: '复制',
                  onPressed: onCopy,
                  icon: const Icon(Icons.content_copy),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
