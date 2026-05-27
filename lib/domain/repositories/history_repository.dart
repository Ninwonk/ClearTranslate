import '../entities/history_record.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryRecord>> listRecent();

  Future<void> add(HistoryRecord record);

  Future<void> delete(String id);

  Future<void> clear();
}
