import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
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

class _HistoryBody extends StatefulWidget {
  const _HistoryBody({
    required this.state,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryState state;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onDelete;

  @override
  State<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<_HistoryBody> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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

    final records = _filterRecords(state.records, _query);
    final selectedRecord = _selectedRecord(records);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          final isCompact = constraints.maxWidth < 600;
          final listPane = _HistoryListPane(
            records: records,
            selectedId: selectedRecord?.id,
            searchController: _searchController,
            onSearchChanged: (value) {
              setState(() => _query = value.trim());
            },
            onSelect: (record) {
              if (isCompact) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => _HistoryDetailScreen(
                      record: record,
                      onCopy: widget.onCopy,
                      onDelete: widget.onDelete,
                    ),
                  ),
                );
                return;
              }
              setState(() => _selectedId = record.id);
            },
            onCopy: widget.onCopy,
            onDelete: widget.onDelete,
          );
          final detailPane = _HistoryDetailPane(
            record: selectedRecord,
            onCopy: widget.onCopy,
            onDelete: widget.onDelete,
          );

          if (!isWide) {
            if (isCompact) {
              return listPane;
            }

            return Column(
              children: [
                SizedBox(height: 300, child: listPane),
                const SizedBox(height: 12),
                Expanded(child: detailPane),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 360, child: listPane),
              const SizedBox(width: 12),
              Expanded(child: detailPane),
            ],
          );
        },
      ),
    );
  }

  List<HistoryRecord> _filterRecords(
      List<HistoryRecord> records, String query) {
    if (query.isEmpty) {
      return records;
    }

    final normalized = query.toLowerCase();
    return records.where((record) {
      return record.inputText.toLowerCase().contains(normalized) ||
          record.outputText.toLowerCase().contains(normalized) ||
          (record.model ?? '').toLowerCase().contains(normalized) ||
          (record.provider ?? '').toLowerCase().contains(normalized) ||
          record.sourceLanguage.label.toLowerCase().contains(normalized) ||
          record.targetLanguage.label.toLowerCase().contains(normalized);
    }).toList();
  }

  HistoryRecord? _selectedRecord(List<HistoryRecord> records) {
    if (records.isEmpty) {
      return null;
    }
    for (final record in records) {
      if (record.id == _selectedId) {
        return record;
      }
    }
    return records.first;
  }
}

class _HistoryListPane extends StatelessWidget {
  const _HistoryListPane({
    required this.records,
    required this.selectedId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSelect,
    required this.onCopy,
    required this.onDelete,
  });

  final List<HistoryRecord> records;
  final String? selectedId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<HistoryRecord> onSelect;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: '搜索历史',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空搜索',
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.clear),
                  ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: records.isEmpty
              ? const Center(child: Text('没有匹配的历史记录'))
              : ListView.separated(
                  itemCount: records.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return _HistoryRecordTile(
                      record: record,
                      isSelected: record.id == selectedId,
                      onTap: () => onSelect(record),
                      onCopy: () => onCopy(record.outputText),
                      onDelete: () => onDelete(record.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({
    required this.record,
    required this.isSelected,
    required this.onTap,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryRecord record;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.22)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
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
                    _formatHistoryTime(record.createdAt),
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
                maxLines: 2,
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
      ),
    );
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  const _HistoryDetailScreen({
    required this.record,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryRecord record;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('历史详情')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _HistoryDetailPane(
            record: record,
            onCopy: onCopy,
            onDelete: onDelete,
          ),
        ),
      ),
    );
  }
}

class _HistoryDetailPane extends StatelessWidget {
  const _HistoryDetailPane({
    required this.record,
    required this.onCopy,
    required this.onDelete,
  });

  final HistoryRecord? record;
  final ValueChanged<String> onCopy;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: record == null
          ? const Center(child: Text('选择一条历史记录查看详情'))
          : Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text(
                                '${record!.sourceLanguage.label} -> ${record!.targetLanguage.label}',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                _modeLabel(record!.mode.name),
                                style: theme.textTheme.labelMedium,
                              ),
                              Text(
                                _formatHistoryTime(record!.createdAt),
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: '复制结果',
                          onPressed: () => onCopy(record!.outputText),
                          icon: const Icon(Icons.content_copy),
                        ),
                        IconButton(
                          tooltip: '删除',
                          onPressed: () => onDelete(record!.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('输入', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    SelectableText(record!.inputText),
                    const Divider(height: 28),
                    Text('结果', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: record!.outputText,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        h1: theme.textTheme.titleLarge,
                        h2: theme.textTheme.titleMedium,
                        h3: theme.textTheme.titleSmall,
                        p: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.7),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (record!.model != null || record!.provider != null) ...[
                      const Divider(height: 24),
                      Text(
                        [
                          if (record!.provider != null) record!.provider!,
                          if (record!.model != null) record!.model!,
                        ].join(' / '),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  String _modeLabel(String mode) {
    return switch (mode) {
      'dictionary' => '词典',
      'translate' => '翻译',
      _ => mode,
    };
  }
}

String _formatHistoryTime(DateTime time) {
  final local = time.toLocal();
  return '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
