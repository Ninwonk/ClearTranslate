import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/history_record.dart';
import '../../domain/repositories/history_repository.dart';
import '../../infrastructure/history/local_history_repository.dart';

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => LocalHistoryRepository(),
);

final historyControllerProvider =
    StateNotifierProvider<HistoryController, HistoryState>((ref) {
  final controller = HistoryController(ref.watch(historyRepositoryProvider));
  controller.load();
  return controller;
});

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._repository) : super(const HistoryState());

  final HistoryRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final records = await _repository.listRecent();
      state = state.copyWith(isLoading: false, records: records);
    } on Object catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '读取历史记录失败：$error',
      );
    }
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> clear() async {
    await _repository.clear();
    await load();
  }
}

class HistoryState {
  const HistoryState({
    this.records = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<HistoryRecord> records;
  final bool isLoading;
  final String? errorMessage;

  HistoryState copyWith({
    List<HistoryRecord>? records,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return HistoryState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();
